using PDDL, SymbolicPlanners, Test
using DataFrames, CSV, Dates, Statistics

# Adapted from experiments file in SymbolicPlanners experiments branch


println("Started")
println()

# Select a problem to test
DOMAIN_NAME = "blocksworld"
INSTANCE_PREFIX = "instance-"
INSTANCE = 10

# Load domain and problem
domain_dir = joinpath(@__DIR__, "logical", DOMAIN_NAME)
domain = load_domain(joinpath(domain_dir, "domain.pddl"))
problem = load_problem(joinpath(domain_dir, "$INSTANCE_PREFIX$INSTANCE.pddl"))

# Extract info from problem and domain
state = initstate(domain, problem)
spec = Specification(problem)


## Landmark testing code ##

# Compute a landmark graph
rg = compute_relaxed_landmark_graph(domain, state, spec)

# Remove landmarks that are true in the initial state
landmark_graph_remove_initial_state(rg.first, rg.second.initial_state)

# Add reasonable order edges
approximate_reasonable_orders(rg.first, rg.second)

# Remove cycles from the graph, uncomment if necessary for the planner that uses it
landmark_graph_remove_cycles_complete(rg.first)


# Print the landmark nodes in the final graph
landmark_graph_print(rg.first, rg.second.planning_graph)

# Draw the final graph to a picture
landmark_graph_draw_png(joinpath(@__DIR__, "test.png"), rg.first, rg.second.planning_graph)


## Verification ##

# Create a planner that uses landmarks
planner = LMLocalPlanner(deepcopy(rg.first), rg.second.planning_graph, AStarPlanner(FFHeuristic(), save_search=true), Inf64, Inf64)

# Run the planner on the problem and verify if the solution is valid
println("Verifying interpreted")
println("$(@elapsed sol = planner(domain, state, spec)) seconds")
@test is_goal(spec, domain, sol.trajectory[end])

# Print the states of the solution when landmarks are added or removed
println()
println("Solution steps")
not_reached::Set{Int} = Set(range(1, length = length(rg.first.nodes)))
active::Set{Int} = Set()
for (i::Int, s::GenericState) in enumerate(sol.trajectory)
    println("step $i")
    for (j::Int, lm::LandmarkNode) in enumerate(rg.first.nodes)
        for f::FactPair in lm.landmark.facts
            if (rg.second.planning_graph.conditions[f.var] in s.facts) == (f.value == 1)
                if !(j in active)
                    delete!(not_reached, j)
                    push!(active, j)
                    println("    + lm $j")
                end
            else
                if j in active
                    delete!(active, j)
                    println("    - lm $j")
                end
            end
        end
    end
end

# Check if all landmarks are reached in the solution
if !isempty(not_reached)
    println("Solution did not reach all landmarks!")
end
println()

# Run the planner again on a compiled version of the domain
cdomain, cstate = compiled(domain, state)
println("Verifying compiled")
println("$(@elapsed sol = planner(cdomain, cstate, spec)) seconds")
@test is_goal(spec, cdomain, sol.trajectory[end])
