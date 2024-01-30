
using PDDL, PlanningDomains, SymbolicPlanners

# Extracting landmark for for problem instance 9, blocksworld from PlanningDomains
blocksworld = load_domain(:blocksworld)
bw_problem = load_problem(:blocksworld, "problem-9")

# zhu_givan_landmark_extraction for without verification
landmark_graph = zhu_givan_landmark_extraction(blocksworld, bw_problem)
number_lm = length(landmark_graph.nodes)

# Bw problem 9 contains 41 causal landmarks
println("Bw problem 9 contains $number_lm causal landmarks")

# zhu_givan_landmark_extraction for with verification
# landmark_graph = zhu_givan_landmark_extraction(blocksworld, bw_problem)

