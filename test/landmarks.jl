@testset "Landmarks" begin
  
blocksworld = load_domain(:blocksworld)

for_prop_lm_bw = [7, 11, 15, 16, 25, 27, 29, 35, 41]
for_prop_lm_log = [14, 16, 25, 21, 33]

@testset "Forward" begin

    @testset "blocksworld" begin
    for i in 1:9
        bw_problem_i= load_problem(:blocksworld, "problem-$i")
        @test length(zhu_givan_landmark_extraction(blocksworld, bw_problem_i).nodes) == for_prop_lm_bw[i]
    end
    end

    @testset "logisitics" begin
    for i in 1:5
        logisitics = load_domain(IPCInstancesRepo, "ipc-1998", "logistics-round-2-strips")
        log_problem_i= load_problem(IPCInstancesRepo, "ipc-1998", "logistics-round-2-strips", i)
        @test length(zhu_givan_landmark_extraction(logisitics, log_problem_i).nodes) == for_prop_lm_log[i]
    end
    end

end

end