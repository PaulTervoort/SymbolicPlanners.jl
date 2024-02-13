using PDDL, SymbolicPlanners, Test, PlanningDomains
using Debugger, PDDL, PlanningDomains, SymbolicPlanners
using CSV

println("Started importing")

import SymbolicPlanners
import SymbolicPlanners.build_planning_graph
import SymbolicPlanners.pgraph_init_idxs

println("Start exp")
#results = Vector Tuple String, Tuple Set, Set, Set end end end()
for (DOMAIN_TYPE, DOMAIN_NAME, i) in [("logical", "blocksworld", 20 ), ("logical", "grid", 5 ), ("logical", "miconic", 12 )]

    println("Domain = " , DOMAIN_NAME)
    #experiment
        
        println("\tIteration: ", i)
        # Load Blocksworld domain and single problem

        domain_dir = joinpath(@__DIR__, DOMAIN_TYPE, DOMAIN_NAME)
        domain = load_domain(joinpath(domain_dir, "domain.pddl"))
        problem = load_problem(joinpath(domain_dir, "instance-$(i).pddl"))

        # Initialize state
        #state = initstate(domain, problem)
        #spec = Specification(problem)

        stats = @timed begin
        (node_count, landmark_count, goals) = and_or_landmark_extraction(domain, problem)
        end
        println("\tAND / OR Landmark extraction in ", stats.time, " seconds")
        println("\tNumber of nodes: ", node_count)
        println("\tNumber of landmarks: ", landmark_count)
        println("\tNumber of goals: ", goals)


        #TODO: write to file 
        #data = [1, 2, 3] CSV.write("output.csv", data)
end