# Run using 'julia --project=. experiments/full-extraction-test.jl'
# Can also be ran using 'julia ./experiments/landmark-test.jl' after adding all the bellow packages in the julia pkg manager
using PDDL, SymbolicPlanners, Test, PlanningDomains, DataFrames, Plots, StatsPlots, CategoricalArrays

println("Started")

results = Vector{Tuple{String, Tuple{Set, Set, Set}}}()

# Selected problems from the IPC competitions (See experiments/logical for more details)
blocksworld = [1, 11, 15, 22, 29, 36, 43, 50, 57, 64, 71, 78, 85, 92, 99]

grid = [1, 2, 4, 5]

freecell = [26, 27, 28, 31, 32, 33, 36, 37, 38, 41, 42, 43, 46, 47, 48]

logistics = [1, 10, 18, 21, 27, 34, 41, 49, 55, 61, 64, 69, 71, 78, 82]

miconic = [4, 11, 23, 31, 42, 57, 65, 73, 84, 97, 106, 115, 121, 133, 146]

# Change this to the desired domain
DOMAIN_NAME = "blocksworld"

# Run the landmark extraction for each problem (Make sure the domain is correct)
for i in blocksworld
    println("Problem number: ", i)
    
    ## Load domain and problem ##
    domain_dir = joinpath(@__DIR__, "logical", DOMAIN_NAME)
    domain = load_domain(joinpath(domain_dir, "domain.pddl"))
    problem = load_problem(joinpath(domain_dir, "instance-$(i).pddl"))

    ## Initialize state and specification ##
    state = initstate(domain, problem)
    spec = Specification(problem)

    ## Run Landmark Extraction ##

    maxTime = 600.0
    stats = @timed begin 
        full_landmarks = full_landmark_extraction(domain, problem, maxTime)
    end

    ## Print results ##
    println("Full landmark extraction finished in ", stats.time, " seconds")
    println("Number of landmarks: ", length(full_landmarks[1]))

    ## Add results for plotting ##
    push!(results, ("fc-$(i)", full_landmarks))
end


function plot_results(results::Vector{Tuple{String, Tuple{Set, Set, Set}}}, domain_name::String)
    # Create a DataFrame with the results
    df = DataFrame(domain=String[], problem_number=Int[], FULL=Int[], Backward=Int[], Forward=Int[])

    # Add the results to the DataFrame
    for (domain, (full_landmarks, landmarks, zhu_landmarks)) in results
        problem_number = parse(Int, match(r"\d+", domain).match)
        push!(df, (domain, problem_number, length(full_landmarks), length(landmarks), length(zhu_landmarks)))
    end

    # Sort the DataFrame by problem number
    sorted_df = sort(df, [:problem_number, :domain])

    # Convert domain column to a categorical type with the specified order
    sorted_df.domain = categorical(sorted_df.domain, levels=sorted_df.domain)

    # Melt the DataFrame to combine multiple columns for plotting
    melted_df = stack(sorted_df, Not(:domain, :problem_number))

    variable_order = ["FULL", "Backward", "Forward"]

    # Order the 'variable' column based on the specified order
    melted_df.variable = categorical(melted_df.variable, levels=variable_order)

    # Plot the results with the specified order
    p = groupedbar(
        melted_df.domain,
        melted_df.value,
        group=melted_df.variable,
        order=unique(sorted_df.domain),
        xlabel="Problem instance",
        ylabel="Number of landmarks",
        bar_width=0.8,
        bar_position=:dodge,
        xrotation=45,
        legend=:topleft,
        ylims=(0,5)
    )
    
    savefig(p, "experiments/$(DOMAIN_NAME)_relaxed_full_extraction.png")
end

plot_results(results, DOMAIN_NAME)