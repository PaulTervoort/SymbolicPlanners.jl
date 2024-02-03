using PDDL, SymbolicPlanners, Test, PlanningDomains
using Debugger, PDDL, PlanningDomains, SymbolicPlanners

println("Started")

#results = Vector Tuple String, Tuple Set, Set, Set end end end()
#TODO not consitent with current directory
DOMAIN_TYPE = "logical" # "logical" or "numeric"
DOMAIN_NAME = "blocksworld" # One of "blocksworld", "logistics", "miconic"

import SymbolicPlanners
import SymbolicPlanners.build_planning_graph
import SymbolicPlanners.pgraph_init_idxs

#this is modified from ka's code
function and_or_landmark_extr(domain::Domain, problem::Problem)
    initial_state = initstate(domain, problem)
    spec = Specification(problem)
    pgraph = build_planning_graph(domain, initial_state, spec)
  
    init_idxs = pgraph_init_idxs(pgraph, domain, initial_state)
    label_graph = pgraph_init_idxs(pgraph, init_idxs)
  
    goals = pgraph.act_parents[end]
    #breaks it
    landmark_graph = create_lm_graph(label_graph, goals)
    return landmark_graph
end


#experiment
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
       and_or_landmark = and_or_landmark_extr(domain, problem)
    end
    println("AND / OR Landmark extraction in ", stats.time, " seconds")
    println("Number of landmarks: ", length(and_or_landmark.nodes))
end




  ##PSEUDO
    #  gen_hm_landmarks_super(TASK)  
                #     \\get landmarks
                #     get_hm_landmarks (task)

                #     \\add to landmark graph

                #     if (use_orders)
    #         \\check ordering by reducing graphs
    #  end


    # \\gets all hm landmarks by propagating from initial states
    #  get_hm_landmarks (task)  
                #     \\m subset of init state
                #     get_m_set(m, task, task.get_init_states())

                #   \\mark hm actions to be applied

#   end
  


# function generate_hm_landmarks_super( pgraph)  
#     #TODO what does this line(s) do
#     ##TaskProxy task_proxy(*task)
#     #initialize(task_proxy)
#     compute_h_m_landmarks(task_proxy)
#     # now construct landmarks graph
#     goal_subsets = Set()
#     goals = pgraph.act_parents[end]
#     #TODO what does this line(s) do
#     #VariablesProxy variables = task_proxy.get_variables()
#     get_m_sets(variables, m_, goal_subsets, goals)
#     all_lms = Vector() #list<int> all_lms
#     for goal_subset in enumerate goal_subsets #for (const FluentSet &goal_subset : goal_subsets)  
#         #TODO what does this line(s) do
#         #assert(set_indices_.find(goal_subset) != set_indices_.end()) -> assert that goal subset is not the end?

#         set_index = set_indices_[goal_subset]

#         #TODO what does this line(s) do -> how is hm_table used?
#         # if (h_m_table_[set_index].level == -1)  
#         #     if (log.is_at_least_verbose())  
#         #         log << endl << endl << "Subset of goal not reachable !!." << endl << endl << endl
#         #         log << "Subset is: "
#         #         print_fluentset(variables, h_m_table_[set_index].fluents)
#         #         log << endl
#         #      end
#         #  end

#         # set up goals landmarks for processing
#         union_with(all_lms, h_m_table_[set_index].landmarks)

#         # the goal itself is also a lm
#         insert_into(all_lms, set_index)

#         # make a node for the goal, with in_goal = true
#         add_lm_node(set_index, true)
#      end
#     # now make remaining lm nodes
#     for lm in enumerate all_lms  
#         add_lm_node(lm, false)
#      end


#     # < NOTE! > this is where ordering would be checked if we cared!!

#     #TODO what does this line(s) do
#     # postprocess(task_proxy)
#  end

#  #TASKPROXY: WTF IS IT 
#  # cant find it
#  # information alg needs from it: 
#  #              get_m_sets params : task_proxy.get_variables() ,  task_proxy.get_initial_state()
#  #                                  -state /problem variables??         initial_states.
#  #assumption: it contains problem but now called "task"

# function compute_h_m_landmarks(task_proxy) 
#     # get subsets of initial state
#     vector<FluentSet> init_subsets;
#     get_m_sets(task_proxy.get_variables(), m_, init_subsets, task_proxy.get_initial_state());
    
#     #TODO what does this line(s) do
#     #TriggerSet current_trigger, next_trigger;

#     # for all of the initial state <= m subsets, mark level = 0
#     for i in 1:length(init_subsets)
#         index = set_indices_[init_subsets[i]];
#         h_m_table_[index].level = 0;

#         # set actions to be applied
#         propagate_pm_fact(index, true, current_trigger);
#     end

#     # mark actions with no precondition to be applied
#     for i in 1:length(pm_ops_)
#         if (unsat_pc_count_[i].first == 0) 
#             # create empty set or clear prev entries
#             current_trigger[i].clear();
#         end
#     end

#     iterator = Vector() #vector<int>::iterator it;
#     operation_iterator = Vector() #TriggerSet::iterator op_it;

#     #TODO : 5sec google finds that triggerset is weird C++ event management class : https://www.cgl.ucsf.edu/chimera/docs/ProgrammersGuide/WhitePapers/trigger-c++.html
#     # how to replace this?



#     local_landmarks = Vector()
#     local_necessary = Vector()

#     prev_size

#     level = 1
# #TODO this loop uses trigger class features, does julia have this??
#     #JUlia has missing content for event handling https://www.juliawiki.com/wiki/Callbacks_and_Event_Handling_(Julia_programming_language)
#     # need to find workaround
#     #https://docs.julialang.org/en/v1/manual/asynchronous-programming/#man-asynchronous -> use channels? this is how julia does asynchonous relaxed_task_solvable

# #     # while we have actions to apply
# #     while (!current_trigger.empty()) 
# #         for (operation_iterator = current_trigger.begin(); operation_iterator != current_trigger.end(); ++operation_iterator) 
# #             local_landmarks.clear();
# #             local_necessary.clear();

# #             int op_index = operation_iterator->first;
# #             PMOp &action = pm_ops_[op_index];

# #             # gather landmarks for pcs
# #             # in the set of landmarks for each fact, the fact itself is not stored
# #             # (only landmarks preceding it)
# #             for (it = action.pc.begin(); it != action.pc.end(); ++it) 
# #                 union_with(local_landmarks, h_m_table_[*it].landmarks);
# #                 insert_into(local_landmarks, *it);

# #                 if (use_orders) 
# #                     insert_into(local_necessary, *it);
# #                 end
# #             end

# #             for (it = action.eff.begin(); it != action.eff.end(); ++it) 
# #                 if (h_m_table_[*it].level != -1) 
# #                     prev_size = h_m_table_[*it].landmarks.size();
# #                     intersect_with(h_m_table_[*it].landmarks, local_landmarks);

# #                     # if the add effect appears in local landmarks,
# #                     # fact is being achieved for >1st time
# #                     # no need to intersect for gn orderings
# #                     # or add op to first achievers
# #                     if (!contains(local_landmarks, *it)) 
# #                         insert_into(h_m_table_[*it].first_achievers, op_index);
# #                         if (use_orders) 
# #                             intersect_with(h_m_table_[*it].necessary, local_necessary);
# #                         end
# #                     end

# #                     if (h_m_table_[*it].landmarks.size() != prev_size)
# #                         propagate_pm_fact(*it, false, next_trigger);
# #                 end else 
# #                     h_m_table_[*it].level = level;
# #                     h_m_table_[*it].landmarks = local_landmarks;
# #                     if (use_orders) 
# #                         h_m_table_[*it].necessary = local_necessary;
# #                     end
# #                     insert_into(h_m_table_[*it].first_achievers, op_index);
# #                     propagate_pm_fact(*it, true, next_trigger);
# #                 end
# #             end

# #             # landmarks changed for action itself, have to recompute
# #             # landmarks for all noop effects
# #             if (operation_iterator->second.empty()) 
# #                 for (size_t i = 0; i < action.cond_noops.size(); ++i) 
# #                     # actions pcs are satisfied, but cond. effects may still have
# #                     # unsatisfied pcs
# #                     if (unsat_pc_count_[op_index].second[i] == 0) 
# #                         compute_noop_landmarks(op_index, i,
# #                                                local_landmarks,
# #                                                local_necessary,
# #                                                level, next_trigger);
# #                     end
# #                 end
# #             end
# #             # only recompute landmarks for conditions whose
# #             # landmarks have changed
# #             else 
# #                 for (set<int>::iterator noop_it = operation_iterator->second.begin();
# #                      noop_it != operation_iterator->second.end(); ++noop_it) 
# #                     assert(unsat_pc_count_[op_index].second[*noop_it] == 0);

# #                     compute_noop_landmarks(op_index, *noop_it,
# #                                            local_landmarks,
# #                                            local_necessary,
# #                                            level, next_trigger);
# #                 end
# #             end
# #         end
# #         current_trigger.swap(next_trigger);
# #         next_trigger.clear();

# #         if (log.is_at_least_verbose()) 
# #             log << "Level " << level << " completed." << endl;
# #         end
# #         ++level;
# #     end
# #     if (log.is_at_least_normal()) 
# #         log << "h^m landmarks computed." << endl;
# #     end
# # end


# #TODO impl
# function get_m_sets(variables, m, initial_subsets, initial_state)
#     set = Vector()
# end