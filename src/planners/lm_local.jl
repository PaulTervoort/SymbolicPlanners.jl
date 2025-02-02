export LMLocalPlanner

"""
    LMLocalPlanner(;
        lm_graph::LandmarkGraph,
        p_graph::PlanningGraph,
        internal_planner::Planner,
        max_time::Float64 = Inf,
        max_mem::Float64 = Inf
    )

Landmark based planner that exploits landmarks by using them as intermediary goals.
Landmark graphs given to this planner should not contain any cycles. Due to the need for sources of the graph for each step of the algorithm.

Original procedure would use disjunctive goals but due to lack of support for that the following steps are used.
    1. Get current sources of the landmark graph
    2. For each source:
        1. Copy the internal planner
        2. Solve for source
        3. Compare with saved solution, if shorter save this solution, planner and landmark
    3. Remove used landmark from landmark graph
    4. Update Internal Planner and Solution.
    5. Repeat from step 1 untill landmark graph is empty.
    6. Solve for orginal goal.

    [1] B. van Maris, "Landmarks in Planning: Using landmarks as Intermediary Goals or as a Pseudo-Heuristic",
    Delft University of Technology.
"""

@kwdef mutable struct LMLocalPlanner <: Planner
    # Landmark Graph that is used to generate intermediary goals
    lm_graph::LandmarkGraph
    # Planning graph to match the LM graph
    p_graph::PlanningGraph
    # Planner used to solve the problem
    internal_planner::Planner
    # Max timout in seconds
    max_time::Float64 = Inf
    # Max memory in bytes
    max_mem::Float64 = Inf
end

function LMLocalPlanner(lm_graph::LandmarkGraph, p_graph::PlanningGraph, internal_planner::Planner, max_time::Float64)
    return LMLocalPlanner(lm_graph, p_graph, internal_planner, max_time, Inf)
end

function solve(planner::LMLocalPlanner,
                domain::Domain, state::State, spec::Specification)
    @unpack lm_graph, p_graph, internal_planner, max_time = planner
    internal_planner.max_time = max_time 
    @unpack h_mult, heuristic, save_search = internal_planner
    saved_lm_graph = deepcopy(lm_graph)
    
    # Simplify goal specification
    spec = simplify_goal(spec, domain, state)
    # Precompute heuristic information
    precompute!(heuristic, domain, state, spec)
    # Initialize search tree and priority queue
    node_id = hash(state)
    search_tree = Dict(node_id => PathNode(node_id, state, 0.0))
    est_cost::Float32 = h_mult * compute(heuristic, domain, state, spec)
    priority = (est_cost, est_cost, 0)
    queue = PriorityQueue(node_id => priority)
    search_order = UInt[]
    sol = PathSearchSolution(:in_progress, Term[], Vector{typeof(state)}(), 0, search_tree, queue, search_order)

    start_time = time()
    while (length(lm_graph.nodes) > 0)
        if time() - start_time >= planner.max_time || gc_live_bytes() > planner.max_mem
            sol.status = :max_time # Time budget reached
            return sol
        end

        sources = get_sources(lm_graph)
        if (length(sources) == 0)
            println("No more sources")
            break
        end
        # For each next up LM compute plan to get there, take shortest and add to final solution
        shortest_sol = nothing
        used_lm = nothing
        used_planner = nothing
        # TODO evaluate NECESSARY edges first and only those if they exist (Speed up performance)
        for lm in sources
            # Copy planner so we dont get side effects
            copy_planner = deepcopy(internal_planner)
            copy_planner.max_time = planner.max_time- (time() - start_time)
            sub_sol = deepcopy(sol)
            inter_spec = Specification(landmark_to_terms(lm.landmark, p_graph))
            sub_sol.status = :in_progress
            sub_sol = search!(sub_sol, copy_planner, domain, inter_spec)
            # If we hit a timeout return the solution we are currently on.
            if sub_sol.status == :max_time
                return sub_sol
            end
            # Update used/Shortest Solution.
            if isnothing(shortest_sol) 
                shortest_sol = sub_sol 
                used_lm = lm
                used_planner = copy_planner
            elseif length(sub_sol.trajectory) < length(shortest_sol.trajectory)
                shortest_sol = sub_sol
                used_lm = lm
                used_planner = copy_planner
            end
        end
        landmark_graph_remove_occurences(lm_graph, used_lm)
        landmark_graph_remove_node(lm_graph, used_lm)    
        # Update internal_planner and sol
        internal_planner = used_planner
        sol = shortest_sol
    end
    sol.status = :in_progress
    sol = search!(sol, internal_planner, domain, spec)

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