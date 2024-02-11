using PDDL, SymbolicPlanners, Test, PlanningDomains
using Debugger, PDDL, PlanningDomains, SymbolicPlanners

println("Started")

#results = Vector Tuple String, Tuple Set, Set, Set end end end()
#TODO not consitent with current directory
DOMAIN_TYPE = "logical" # "logical" or "numeric"
DOMAIN_NAME = "blocksworld" # One of "blocksworld", "logistics", "miconic"

import SymbolicPlanners
import SymbolicPlanners.build_planning_graph
import SymbolicPlanners.pgraph_init_idxs

#experiment
for i in 1:9
    println("Iteration: ", i)
    # Load Blocksworld domain and single problem

    domain_dir = joinpath(@__DIR__, DOMAIN_TYPE, DOMAIN_NAME)
    domain = load_domain(joinpath(domain_dir, "domain.pddl"))
    problem = load_problem(joinpath(domain_dir, "instance-$(i).pddl"))

    # Initialize state
    #state = initstate(domain, problem)
    #spec = Specification(problem)

    stats = @timed begin
       (node_count, landmark_count) = and_or_landmark_extraction(domain, problem)
    end
    println("AND / OR Landmark extraction in ", stats.time, " seconds")
    println("Number of nodes: ", node_count)
    println("Number of landmarks: ", landmark_count)
end