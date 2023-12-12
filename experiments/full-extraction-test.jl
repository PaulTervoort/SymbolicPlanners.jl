# Run using 'julia --project=. experiments/full-extraction-test.jl'
# Can also be ran using 'julia ./experiments/landmark-test.jl' after adding all the bellow packages in the julia pkg manager
using PDDL, SymbolicPlanners, Test, PlanningDomains

println("Started")

# Load Blocksworld domain and single problem
domain = load_domain(:blocksworld)
problem = load_problem(:blocksworld, "problem-2")
# Initialize state
state = initstate(domain, problem)
spec = Specification(problem)

# Add our planner here
planner = AStarPlanner(HAdd(), save_search=true)

## Run Planner ##

println("Verifying landmark extraction")
stats = @timed begin
    landmarks = full_landmark_extraction(domain, problem)
end
# @test is_goal(spec, domain, sol.trajectory[end])
println("Landmark extraction finished in ", stats.time, " seconds")

