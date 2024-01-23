# Run using 'julia --project=. experiments/full-extraction-test.jl'
# Can also be ran using 'julia ./experiments/landmark-test.jl' after adding all the bellow packages in the julia pkg manager
using PDDL, SymbolicPlanners, Test, PlanningDomains, DataFrames, Plots, StatsPlots

println("Started")

results = Vector{Tuple{String, Tuple{Set, Set, Set}}}()

for i in 1:9
    println("Iteration: ", i)
    # Load Blocksworld domain and single problem
    domain = load_domain(:blocksworld)
    problem = load_problem(:blocksworld, "problem-$(i)")
    # Initialize state
    state = initstate(domain, problem)
    spec = Specification(problem)

    # Add our planner here
    planner = AStarPlanner(HAdd(), save_search=true)

    ## Run Planner ##

    stats = @timed begin
        full_landmarks = full_landmark_extraction(domain, problem)
    end
    println("Full landmark extraction finished in ", stats.time, " seconds")
    println("Number of landmarks: ", length(full_landmarks[1]))

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

plot_results(results, "Blocksworld")