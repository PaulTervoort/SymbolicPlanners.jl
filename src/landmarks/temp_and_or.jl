export and_or_landmark_extraction

"""
TEMP TEMP TEMP THIS IS COPIED!
"""
function map_condition_action(pgraph::PlanningGraph)
  map = Vector{Vector{Int}}()
  condition_size = length(pgraph.conditions)
  resize!(map, condition_size)

  for (i, conditions) in enumerate(pgraph.cond_children)
    map[i] = Vector{Int}()

    for tuple in conditions
      idx_action = tuple[1]
      push!(map[i], idx_action)
    end
  end

  return map 
end

"""
    check_precond_empty(label_layer, preconditions)

Check if labels of the preconditions specified by 'preconditions' are non-empty in 'label_layer'.
"""
function check_precond_empty(label_layer::Vector{Set{Int}}, preconditions::Vector{Vector{Int}})
  for conditions in preconditions
    flag = false
    for condition in conditions 
      if !isempty(label_layer[condition])
        flag = true 
      end
    end
    if(!flag)
      return false
    end
  end
  return true
end

"""
    apply_action_and_propagate(label_layer, next_label_layer, pgraph, action)

Apply label propagation to the effects labels of action.
"""
function apply_action_and_propagate(label_layer::Vector{Set{Int}}, next_label_layer::Vector{Set{Int}}, pgraph::PlanningGraph, action::Int)
  result = Set{Int}()
  union_set_preconditions = union_preconditions(label_layer, pgraph.act_parents[action])

  for effect in pgraph.act_children[action]
    if length(next_label_layer[effect]) == 1
      continue
    end

    union_set_preconditions_effect = union(union_set_preconditions, effect)
    (propagated, new_labels) = check_propagation(next_label_layer[effect], union_set_preconditions_effect, effect)
    next_label_layer[effect] = new_labels

    if propagated
      push!(result, effect)
    end
  end

  return result
end


"""
    check_propagation(old_labels, new_labels, effect)

The union of effect with the intersection of old_labels and new_labels. Return if size changes occured to old_labels and the old_labels.
"""
function check_propagation(old_labels::Set{Int}, new_labels::Set{Int}, effect::Int)
  size_old_labels = length(old_labels)

  if(!isempty(old_labels))
    old_labels = intersect(old_labels, new_labels)
  else
    old_labels = new_labels
  end
  union!(old_labels, effect)

  return Pair(length(old_labels) != size_old_labels, old_labels)
end

"""
    union_preconditions(label_layer, preconditions)

The union of the preconditions labels in label_layer.
"""
function union_preconditions(label_layer::Vector{Set{Int}}, preconditions::Vector{Vector{Int}})
  result = Set{Int}()
  for arr_cond in preconditions
    for cond in arr_cond
      union!(result, label_layer[cond])
    end
  end
  return result
end

"""
    create_label_layer(pgraph, init_idxs)

Create the label layer using pgraph and init_idxs.
"""
function create_label_layer(pgraph::PlanningGraph, init_idxs::BitVector)
  n_conditions = length(pgraph.conditions)
  label_layer::Vector{Set{Int}} = [Set{Int}() for _ in 1:n_conditions]
  condition_action_map = map_condition_action(pgraph)
  queue = Set{Int}()

  # Initialize the initial layer.
  for i in findall(init_idxs)
    push!(label_layer[i], i)
    for action_id in condition_action_map[i]
      push!(queue, action_id)
    end
  end

  while(!isempty(queue))
    next_label_layer = copy(label_layer)
    next_queue = Set{Int}()
    for action in queue
      preconditions = pgraph.act_parents[action]
     
      # Check if the action is applicable
      if (check_precond_empty(label_layer, preconditions))
        changed = apply_action_and_propagate(label_layer, next_label_layer, pgraph, action)
        if (!isempty(changed))
          for condition in changed
            union!(next_queue, condition_action_map[condition])
          end
        end
      end
    end
    label_layer = next_label_layer
    queue = next_queue
  end

  return label_layer
end

"""
    create_lm_graph(label_layer, goals)

Create the landmark graph using the label layer and goals.
"""
function create_lm_graph(label_layer::Vector{Set{Int}}, goals::Vector{Vector{Int}})
  landmark_graph::LandmarkGraph = LandmarkGraph(0, 0, Dict(), Dict(), [])
  
  for goal in goals
    for goal_condition in goal
      goalpair::FactPair = FactPair(goal_condition, 1)

      lm_node = nothing
      # Check if the landmark graph contains the goal landmark
      if (landmark_graph_contains_landmark(landmark_graph, goalpair))
        lm_node = landmark_graph.simple_landmarks_to_nodes[goalpair]
        lm_node.landmark.is_true_in_goal = true
      else
        fact_vector = Vector{FactPair}()
        push!(fact_vector, goalpair)
        lm = Landmark(fact_vector, false, false, true, false, Set{}(), Set{}())
        lm_node = landmark_graph_add_landmark(landmark_graph, lm)
      end
      for condition in label_layer[goal_condition]
        # Check if condition
        if(condition == goal_condition)
          continue
        end
        node = nothing
        factpair::FactPair = FactPair(condition, 1)
        if (!landmark_graph_contains_landmark(landmark_graph, factpair))
          fact_vector = Vector{FactPair}()
          push!(fact_vector, factpair)
          lm = Landmark(fact_vector, false, false, false, false, Set{}(), Set{}())
          node = landmark_graph_add_landmark(landmark_graph, lm)
        else
          node = landmark_graph.simple_landmarks_to_nodes[factpair]
        end
        edge_add(node, lm_node, NATURAL)
      end
    end
  end
  return landmark_graph
end


"""
    zhu_givan_landmark_extraction(domain, problem)

Construct landmark graph that has no noncausal landmark discarded.
"""
function and_or_landmark_extraction(domain::Domain, problem::Problem)
  initial_state = initstate(domain, problem)
  spec = Specification(problem)
  pgraph = build_planning_graph(domain, initial_state, spec)

  init_idxs = pgraph_init_idxs(pgraph, domain, initial_state)
  label_graph = create_label_layer(pgraph, init_idxs)

  goals = pgraph.act_parents[end]
  landmark_graph = create_lm_graph(label_graph, goals)
  return landmark_graph
end

function and_or_process(planning_graph::PlanningGraph, goal::Term)
  # Initialize landmarks for all nodes
  landmarks = Dict{Int, Set{Int}}()
  for i in 1:length(planning_graph.conditions)
      landmarks[i] = Set([i])
  end

  for i in 1:length(planning_graph.actions)
      landmarks[i + planning_graph.n_goals] = Set([i + planning_graph.n_goals])
  end

  # Update landmarks until fixpoint is reached
  while true
      updated_landmarks = copy(landmarks)

      for i in 1:length(planning_graph.conditions)
          # Update landmarks for condition nodes
          if !planning_graph.cond_derived[i]
              parents = get_parents(planning_graph, i)
              updated_landmarks[i] = Set([i]) ∪ ∩([landmarks[parent] for parent in parents])
          end
      end

      for i in 1:length(planning_graph.actions)
          # Update landmarks for action nodes
          children = planning_graph.act_children[i]
          updated_landmarks[i + planning_graph.n_goals] = Set([i + planning_graph.n_goals]) ∪ ⋂([landmarks[child] for child in children])
      end

      # Check for fixpoint
      if updated_landmarks == landmarks
          break
      end

      landmarks = updated_landmarks
  end

  # Return the set of landmarks for the goal node
  goal_node_index = findfirst(x -> x == goal, planning_graph.conditions)
  return ∪([landmarks[goal_node_index] for goal_node_index in goal_node_indices])
end

function get_parents(planning_graph::PlanningGraph, node_index::Int)
  parents = Set{Int}()

  for (i, children) in enumerate(planning_graph.cond_children)
      if any(x -> x == node_index, children)
          push!(parents, i)
      end
  end

  return parents
end
