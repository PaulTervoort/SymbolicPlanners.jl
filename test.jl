using Debugger, PDDL, PlanningDomains, SymbolicPlanners


function loadProblem(n)
domain = load_domain("Hiking/domain.pddl")
problem = load_problem("Hiking/problem-6.pddl")
state = initstate(domain, problem)


spec = MinStepsGoal(PDDL.get_goal(problem))

planner = AStarPlanner(FFHeuristic())

# planner = FastDownward("astar", "ff", 300,  true, true, "~/home/ky/project/downward/", )

sol = planner(domain, state, spec)
return sol
end

@enter loadProblem(:doors_keys_gems)

