using PDDL, SymbolicPlanners, Test, Debugger

println("Started")


results = Vector{Tuple{String, Tuple{Set, Set, Set}}}()
DOMAIN_NAME = "logistics" # One of "blocksworld", "logistics", "miconic"


for i in 81:81
    println("Iteration: ", i)
    # Load Blocksworld domain and single problem

    domain_dir = joinpath(@__DIR__, "logical", DOMAIN_NAME)
    domain = load_domain(joinpath(domain_dir, "domain.pddl"))
    problem = load_problem(joinpath(domain_dir, "instance-$(i).pddl"))
    # problem = load_problem(joinpath(domain_dir, "pfile$(i).pddl"))
    # Initialize state
    state = initstate(domain, problem)
    spec = Specification(problem)

    stats = @timed begin
        zhu_givan_landmark = zhu_givan_landmark_extraction(domain, problem)
    end
    println("Zhu Givan Landmark extraction in ", stats.time, " seconds")
    println("Number of landmarks: ", length(zhu_givan_landmark.nodes))
end
