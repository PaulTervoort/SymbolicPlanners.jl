# Run using 'julia --project=. experiments/full-extraction-test.jl'
# Can also be ran using 'julia ./experiments/landmark-test.jl' after adding all the bellow packages in the julia pkg manager
using PDDL, SymbolicPlanners, Test, PlanningDomains, DataFrames, Plots, StatsPlots

println("Started")

results = Vector{Tuple{String, Tuple{Set, Set, Set}}}()

blocksworld = [1, 11, 15, 22, 29, 36, 43, 50, 57, 64, 71, 78, 85, 92, 99]

freecell = [26, 27, 28, 31, 32, 33, 36, 37, 38, 41, 42, 43, 46, 47, 48]

DOMAIN_NAME = "blocksworld"

for i in blocksworld
    println("Problem number: ", i)
    
    ## Load domain and problem ##
    domain_dir = joinpath(@__DIR__, "logical", DOMAIN_NAME)
    domain = load_domain(joinpath(domain_dir, "domain.pddl"))
    problem = load_problem(joinpath(domain_dir, "instance-$(i).pddl"))

    ## Initialize state and specification ##
    state = initstate(domain, problem)
    spec = Specification(problem)

    ## Initialize planner ##
    planner = OrderedLandmarksPlanner()

    ## Run Planner ##

    stats = @timed begin
        full_landmarks = full_landmark_extraction(domain, problem)
    end

    ## Print results ##
    println("Full landmark extraction finished in ", stats.time, " seconds")
    println("Number of landmarks: ", length(full_landmarks[1]))

    ## Add results for plotting ##
    push!(results, ("bw-$(i)", full_landmarks))
end


function plot_results(results::Vector{Tuple{String, Tuple{Set, Set, Set}}}, domain_name::String)
    df = DataFrame(domain=String[], full_landmarks=Int[], landmarks=Int[], zhu_landmarks=Int[])

    for (domain, (full_landmarks, landmarks, zhu_landmarks)) in results
        push!(df, (domain, length(full_landmarks), length(landmarks), length(zhu_landmarks)))
    end

    # Melt the DataFrame to combine multiple columns for plotting
    melted_df = stack(df, Not(:domain))

    p = groupedbar(
        melted_df.domain,
        melted_df.value,
        group=melted_df.variable,
        xlabel="Problem instance",
        ylabel="Number of landmarks",
        title="Full landmark extraction of $(domain_name)",
        bar_width=0.8,
        bar_position=:dodge,
        xrotation=45,
        legend=:topleft
    )
    
    savefig(p, "$(domain_name)-full_extraction.png")
end

plot_results(results, DOMAIN_NAME)