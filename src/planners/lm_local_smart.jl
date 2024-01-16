export LMLocalSmartPlanner

"""
"""

@kwdef mutable struct LMLocalSmartPlanner <: Planner
    # Landmark Graph that is used to generate intermediary goals
    lm_graph::LandmarkGraph
    # Planning graph to match the LM graph
    gen_data::LandmarkGenerationData
    # Planner used to solve the problem
    internal_planner::Planner
    # Max timout in seconds
    max_time::Float64 = Inf
    # Max memory in bytes
    max_mem::Float64 = Inf
end

function LMLocalSmartPlanner(lm_graph::LandmarkGraph, gen_data::LandmarkGenerationData, internal_planner::Planner, max_time::Float64)
    return LMLocalSmartPlanner(lm_graph, gen_data, internal_planner, max_time, Inf)
end

function solve(planner::LMLocalSmartPlanner,
                domain::Domain, state::State, spec::Specification)
    @unpack lm_graph, gen_data, internal_planner = planner
    @unpack h_mult, heuristic, save_search = internal_planner
    p_graph = gen_data.planning_graph
    saved_lm_graph = deepcopy(lm_graph)

    # Generate Terms for each Landmark
    lm_id_to_terms::Dict{Int, Term} = Dict()
    for (idx, lm) in enumerate(lm_graph.nodes)
        lm.id = idx
        term = p_graph.conditions[first(lm.landmark.facts).var] #landmark_to_terms(lm.landmark, p_graph)
        if first(lm.landmark.facts).value == 0
            term = Compound(:not, [term])
        end
        lm_id_to_terms[lm.id] = term
    end
    
    # Create compatibility Matrix for all terms/landmarks
    nr_nodes = length(lm_graph.nodes)
    compat_mat = trues(nr_nodes, nr_nodes)
    for i in 1:nr_nodes
        for j in i+1:nr_nodes
            sat = !interferes(lm_graph.nodes[i].landmark, lm_graph.nodes[j].landmark, gen_data)
            # sat = PDDL.satisfy(domain, state, Compound(:and, [lm_id_to_terms[i], lm_id_to_terms[j]]))
            compat_mat[i,j] = sat
            compat_mat[j,i] = sat
        end
    end
    # Simplify goal specification
    spec = simplify_goal(spec, domain, state)
    # Precompute heuristic information
    precompute!(heuristic, domain, state, spec)
    # Initialize search tree and priority queue
    node_id = hash(state)
    search_tree = Dict(node_id => PathNode(node_id, state, 0.0))
    est_cost = h_mult * compute(heuristic, domain, state, spec)
    priority = (est_cost, est_cost, 0)
    queue = PriorityQueue(node_id => priority)
    search_order = UInt[]
    sol = PathSearchSolution(:in_progress, Term[], Vector{typeof(state)}(), 0, search_tree, queue, search_order)
    plan = Term[]
    trajectory = Vector{typeof(state)}()
    expanded = 0

    start_time = time()
    time_factor = 1
    timeout_bak = internal_planner.max_time
    while (length(lm_graph.nodes) > 0)
        if time() - start_time >= planner.max_time || gc_live_bytes() > planner.max_mem
            sol.status = :max_time # Time budget reached
            return sol
        end
        
        sources = get_sources(lm_graph)
        if (length(sources) == 0) 
            println("No new sources")
            break 
        end

        # goal_nodes::Vector{Set{LandmarkNode}} = Vector()
        # for i in sources
        #     new_gs = []
        #     added = false
        #     for g in goal_nodes
        #         g_new = filter(n -> compat_mat[i.id, n.id], g)
        #         if length(g) == length(g_new)
        #             added = true
        #             push!(g, i)
        #         elseif length(g_new) > 0
        #             added = true
        #             push!(g_new, i)
        #             isnew = true
        #             for ng in new_gs
        #                 if issetequal(ng, g_new)
        #                     isnew = false
        #                 end
        #             end
        #             if isnew
        #                 push!(new_gs, g_new)
        #             end
        #         end
        #     end
        #     if !added
        #         push!(goal_nodes, Set([i]))
        #     end
        #     append!(goal_nodes, new_gs)
        # end
        # goal_terms = map(s -> map(n -> lm_id_to_terms[n.id], collect(s)), goal_nodes)
        goal_terms = map(n -> [lm_id_to_terms[n.id]], collect(sources))
        println("goals: $goal_terms")

        # For each next up Goal compute plan to get there, take shortest and add to final solution
        shortest_sol = nothing
        used_planner = nothing
        most_sources_true = 0
        first_early = false
        for goal in goal_terms
            # Copy planner so we dont get side effects
            copy_planner = deepcopy(internal_planner)
            copy_planner.max_time = min(timeout_bak * time_factor, planner.max_time + start_time - time())
            sub_sol = deepcopy(sol)
            inter_spec = Specification(goal)
            # Precompute heuristic information
            precompute!(heuristic, domain, state, inter_spec)
            # Initialize search tree and priority queue
            node_id = hash(state)
            est_cost = h_mult * compute(heuristic, domain, state, inter_spec)
            priority = (est_cost, est_cost, 0)
            sub_sol.search_tree = Dict(node_id => PathNode(node_id, state, 0.0))
            sub_sol.search_frontier = PriorityQueue(node_id => priority)
            sub_sol.search_order = UInt[]
            sub_sol.status = :in_progress
            sub_sol = search!(sub_sol, copy_planner, domain, inter_spec)
            if isnothing(shortest_sol)
                if sub_sol.status == :max_time
                    first_early = true
                else
                    for lm in lm_graph.nodes
                        for goal in sub_sol.trajectory
                            if is_goal(Specification(lm_id_to_terms[lm.id]), domain, goal)
                                if lm in sources
                                    most_sources_true += 1
                                else
                                    first_early = true
                                end
                                break
                            end
                        end
                        if first_early
                            break
                        end
                    end
                end
                shortest_sol = sub_sol 
                used_planner = copy_planner
            else
                early_lm = false
                sources_true = 0
                if sub_sol.status == :max_time
                    early_lm = true
                else
                    for lm in lm_graph.nodes
                        for goal in sub_sol.trajectory
                            if is_goal(Specification(lm_id_to_terms[lm.id]), domain, goal)
                                if lm in sources
                                    sources_true += 1
                                else
                                    early_lm = true
                                end
                                break
                            end
                        end
                        if early_lm
                            break
                        end
                    end
                end
                if (!early_lm || (first_early && early_lm)) && (sources_true > most_sources_true || (sources_true == most_sources_true && length(sub_sol.trajectory) < length(shortest_sol.trajectory)))
                    first_early = early_lm
                    shortest_sol = sub_sol
                    used_planner = copy_planner
                    most_sources_true = sources_true
                end
            end
        end
        if shortest_sol.status == :max_time
            time_factor *= 2
            continue
        else
            time_factor = 1
        end
        # Update internal_planner and sol
        internal_planner = used_planner
        sol = shortest_sol
        state = sol.trajectory[end]

        append!(trajectory, sol.trajectory[1:end-1])
        append!(plan, sol.plan)
        expanded += sol.expanded
        # println("state: $(GenericState(state).facts)")
        # Find LM that was solved and remove it from LM graph
        for lm in sources
            for goal in sol.trajectory
                if is_goal(Specification(lm_id_to_terms[lm.id]), domain, goal)
                    landmark_graph_remove_occurences(lm_graph, lm)
                    landmark_graph_remove_node(lm_graph, lm)
                end
            end
        end
    end
    node_id = hash(state)
    search_tree = Dict(node_id => PathNode(node_id, state, 0.0))
    est_cost::Float32 = h_mult * compute(heuristic, domain, state, spec)
    priority = (est_cost, est_cost, 0)
    queue = PriorityQueue(node_id => priority)
    search_order = UInt[]
    sol2 = PathSearchSolution(:in_progress, Term[], Vector{typeof(state)}(), 0, search_tree, queue, search_order)
    sol2 = search!(sol2, internal_planner, domain, spec)
    append!(plan, sol2.plan)
    sol.plan = plan
    append!(trajectory, sol2.trajectory)
    sol.trajectory = trajectory
    expanded += sol2.expanded
    sol.expanded = expanded

    # Reset internal LM Graph to prevent not using landmarks in subsequent runs
    planner.lm_graph = saved_lm_graph

    # Return solution
    if save_search
        return sol
    elseif sol.status == :failure
        return NullSolution(sol.status)
    else
        return PathSearchSolution(sol.status, sol.plan, sol.trajectory)
    end
end
