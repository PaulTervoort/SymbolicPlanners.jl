using PDDL, SymbolicPlanners, Test, PlanningDomains
using DataFrames, CSV, Dates, Statistics

planners = ["HAdd", "LM_Local-HAdd", "LM_Local_Smart-HAdd"]
benchmark_file = "fp-benchmark.txt"

# Parse benchmark file
domains::Vector{Pair{String, String}} = []
instances::Dict{String, Vector{Pair{String, String}}} = Dict()

function parse_benchmark(benchmark_file_path::String)
    domain_string::String = ""
    domain_path::String = ""
    lines::Vector{String} = readlines(joinpath(@__DIR__, benchmark_file_path))
    for s::String in lines
        if s[1:3] == " - " && !isempty(domain_string)
            s_parts::Vector{String} = split(s[3:end], '=')
            if length(s_parts) == 2 && !(' ' in strip(s_parts[1])) && '/' in s_parts[2]
                instance_string::String = strip(s_parts[1])
                instance_path::String = strip(s_parts[2])
                if isempty(domain_path)
                    parts::Vector{String} = split(instance_path, '/')
                    domain_path = joinpath(dirname(@__DIR__), joinpath(parts[1:length(parts) - 1]), "domain.pddl")
                end

                if !haskey(instances, domain_string)
                    push!(domains, Pair(domain_string, domain_path))
                    instances[domain_string] = []
                end
                push!(instances[domain_string], Pair(instance_string, joinpath(dirname(@__DIR__), instance_path)))
            end
        elseif !(' ' in strip(s))
            domain_string = strip(s)
            domain_path = ""
        end
    end
end
parse_benchmark(benchmark_file)

TIMEOUT = 180.0
NRUNS = 3

# Store results in data frame
df = DataFrame(domain=String[], problem=String[], problem_size=Int[],
               compiled=Bool[], run=Int[], time=Float64[], n_landmarks=Int[],
               extract_type=String[])

#JuliaPlannerRepo domains
for (d_name::String, d_path::String) in domains
    domain = load_domain(d_path)
    df_name = "$(d_name)-results-$(today()).csv"

    println("======================= Domain: $d_name =======================")
    for (p_name::String, p_path::String) in instances[d_name]
        problem = load_problem(p_path)
        psize = length(PDDL.get_objects(problem))

        println("- Starting Problem: $p_name, with Size: $psize")
        
        # Initialize state and specification
        state = initstate(domain, problem)
        spec = Specification(problem)
        # Compile domain
        cdomain, cstate = compiled(domain, state)
        
        # Repeat for both original and compiled
        for dom in (domain, cdomain)
            # Indicate if we do Compiled or Interpreted
            state = initstate(dom, problem)
            #Create LM graph
            # lm_graph::LandmarkGraph, gen_data::SymbolicPlanners.LandmarkGenerationData = compute_relaxed_landmark_graph(dom, state, spec)
            

            nruns = dom isa CompiledDomain ? NRUNS + 1 : NRUNS
            timed_out = false
            # Run and time planner
            #
            #
            for extract in ["forward", "backward", "noncausal"]
              for i in 1:nruns
                  if timed_out continue end
              
                  size_landmarks = -1
                  lm_graph = nothing
                  time = -1
                    stats = nothing
                    if extract == "forward"
                      stats = @timed begin
                        lm_graph = zhu_givan_landmark_extraction(dom, problem)
                      end
                      size_landmarks = length(lm_graph.nodes)
                    elseif extract == "backward"
                      try
                        stats = @timed begin
                          lm_graph , gen_data = compute_relaxed_landmark_graph(dom, state, spec)
                        end
                        size_landmarks = length(lm_graph.nodes)
                        time = stats.time
                      catch
                        continue
                      end

                    else
                      try
                        stats = @timed begin
                          lm_graph , gen_data = zhu_givan_landmark_extraction_noncausal(dom, problem)
                        end
                        size_landmarks = length(lm_graph.nodes)
                        time = stats.time
                      catch
                        continue
                      end
                    end 
                    println("time: ", stats.time, " seconds")
                    row = (
                        domain = d_name,
                        problem = p_name,
                        problem_size = psize,
                        compiled = (dom isa CompiledDomain),
                        run = i,
                        time = stats.time,
                        n_landmarks = size_landmarks,
                        extract_type = extract
                    )
                    push!(df, row)
                    GC.gc()
                end

            end
        end
        println()
    end
    CSV.write(df_name, df)
    global df = DataFrame(domain=String[], problem=String[], problem_size=Int[],
              compiled=Bool[], run=Int[], time=Float64[], n_landmarks=Int[],
              extract_type=String[])
    GC.gc()
end

