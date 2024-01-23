using PDDL, SymbolicPlanners, Test, PlanningDomains
using Debugger, PDDL, PlanningDomains, SymbolicPlanners

println("Started")


results = Vector{Tuple{String, Tuple{Set, Set, Set}}}()
#TODO not consitend with current directory
DOMAIN_TYPE = "logical" # "logical" or "numeric"
DOMAIN_NAME = "blocksworld" # One of "blocksworld", "logistics", "miconic"


for i in 1:9
    println("Iteration: ", i)
    # Load Blocksworld domain and single problem

    domain_dir = joinpath(@__DIR__, DOMAIN_TYPE, DOMAIN_NAME)
    domain = load_domain(joinpath(domain_dir, "domain.pddl"))
    problem = load_problem(joinpath(domain_dir, "instance-$(i).pddl"))

    # Initialize state
    state = initstate(domain, problem)
    spec = Specification(problem)

    stats = @timed begin
        zhu_givan_landmark = zhu_givan_landmark_extraction(domain, problem)
    end
    println("Zhu Givan Landmark extraction in ", stats.time, " seconds")
    println("Number of landmarks: ", length(zhu_givan_landmark.nodes))
end
