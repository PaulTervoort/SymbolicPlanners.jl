using PDDL, SymbolicPlanners, Test, PlanningDomains
using Debugger, PDDL, PlanningDomains, SymbolicPlanners

println("Started")
#TODO ; make this file not zhnu & givan

results = Vector{Tuple{String, Tuple{Set, Set, Set}}}()
#TODO not consitent with current directory
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
        zhu_givan_landmark = and_or_landmark_extraction(domain, problem)
    end
    println("Zhu Givan Landmark extraction in ", stats.time, " seconds")
    println("Number of landmarks: ", zhu_givan_landmark)
end
