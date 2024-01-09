export compute_propagation
export zhu_givan_landmark_extraction

mutable struct graph_node
  labels::Set{Int}
  graph_node() = new()
end

function compute_propagation(pgraph::PlanningGraph)
  triggers = Vector{Vector{Int}}()

  n_conditions = length(pgraph.conditions)
  resize!(triggers, n_conditions)

  for (i, conditions) in enumerate(pgraph.cond_children)
    triggers[i] = Vector{Int}()

    for tuple in conditions
      idx_action, idx_precond = tuple

      push!(triggers[i], idx_action)
    end
  end

  return triggers
end

"Check if the preconditions are not empty."
function check_precond_empty(layer::Vector{graph_node}, precond::Vector{Vector{Int}})
  for conditions in precond
    flag = false
    for cond in conditions 
      if(!isempty(layer[cond].labels))
        flag = true
      end
    end
    if(!flag)
      return false
    end
  end
  return true
end

function apply_action_and_propagate(layer::Vector{graph_node}, pgraph::PlanningGraph, action::Int, next_layer::Vector{graph_node}, triggers::Vector{Vector{Int}})
  result = Set{Int}()

  precond_union = union_preconditions(layer, pgraph.act_parents[action])

  for effect in pgraph.act_children[action]

    eff_lbl_size = length(next_layer[effect].labels)

    if (eff_lbl_size == 1)
      continue
    end

    # precond_effect = copy(precond_union)
    # union_eff = union(precond_effect, effect)

    # union_effects = union_effect(layer, pgraph.act_children[action])
    # union!(precond_effect, union_effects)

    if (labels_propagated(next_layer[effect].labels, precond_union, effect)) 
      push!(result, effect)
      union_eff = union(precond_union, effect)
      next_layer[effect].labels = union_eff
    end
  end

  return result
end

function labels_propagated(old_labels::Set{Int}, new_labels::Set{Int}, condition::Int)
  copy_old = deepcopy(old_labels)

  if(!isempty(old_labels))
    intersect!(old_labels, new_labels)
  else
    old_labels = new_labels
  end

  push!(old_labels, condition)

  return length(old_labels) != length(copy_old)
end

function union_preconditions(layer::Vector{graph_node}, precond::Vector{Vector{Int}})
  result = Set{Int}()

  for out in precond
    for cond in out
      union!(result, layer[cond].labels)
    end
  end
  return result
end

function union_effect(layer::Vector{graph_node}, effect::Vector{Int})
  result = Set{Int}()

  for cond in effect
    union!(result, layer[cond].labels)
  end

  return result
end

function graph_label(pgraph::PlanningGraph, domain::Domain, state::State)

  n_conditions = length(pgraph.conditions)
  triggers = compute_propagation(pgraph)
  
  triggered = Set{Int}()

  init_idxs = pgraph_init_idxs(pgraph, domain, state)
  # prop_layer::Vector{graph_node}()
  prop_layer =  Vector{graph_node}()

  for i in 1:n_conditions
    node = graph_node()
    node.labels = Set{Int}()
    push!(prop_layer, node)
  end

  for i in findall(init_idxs)
    push!(prop_layer[i].labels, i)
  end

  for (i, conditions) in enumerate(pgraph.conditions)
    for action_id in triggers[i]
      push!(triggered, action_id)
    end
  end

  changes = true

  while(changes)
    next_layer = deepcopy(prop_layer)
    next_trigger = Set()
    changes = false
    for i in triggered
      # precond::Vector{Vector{Int}}
      precond = pgraph.act_parents[i]

      if (check_precond_empty(prop_layer, precond))
         
        changed = apply_action_and_propagate(prop_layer, pgraph, i, next_layer, triggers)
        if (!isempty(changed))
        
          changes = true
          for j in changed
            for val in triggers[j]
              push!(next_trigger, val)
            end
          end
        end
      end

    end
    prop_layer = next_layer
    triggered = next_trigger
  end

  return prop_layer
end

function extract_lm(prop_layer::Vector{graph_node}, pgraph::PlanningGraph)
  n_action = length(pgraph.actions)
  n_goals = pgraph.n_goals

  goals = pgraph.act_parents[n_action]

  propagated_landmarks = Set{Landmark}()
  landmark_graph::LandmarkGraph = LandmarkGraph(0, 0, Dict(), Dict(), [])

  for goal in goals
    for condition in goal
      goalpair::FactPair = FactPair(condition, 1)

      lm_node = nothing
      if (landmark_graph_contains_landmark(landmark_graph, goalpair))
        lm_node = landmark_graph.simple_landmarks_to_nodes[goalpair]
        lm_node.landmark.is_true_in_goal = true
      else
        fact_vector = Vector{FactPair}()
        push!(fact_vector, goalpair)
        lm = Landmark(fact_vector, false, false, true, false, Set{}(), Set{}())
        lm_node = landmark_graph_add_landmark(landmark_graph, lm)
      end

      for label in prop_layer[condition].labels
        if(label == condition)
          continue
        end

        node = nothing
        factpair::FactPair = FactPair(label, 1)
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

function zhu_givan_landmark_extraction(domain::Domain, problem::Problem)
  initial_state = initstate(domain, problem)
  spec = Specification(problem)

  statics = infer_static_fluents(domain)
  pgraph = build_planning_graph(domain, initial_state, spec, statics = statics)
  label_graph = graph_label(pgraph, domain , initial_state)
  landmark_graph = extract_lm(label_graph, pgraph)
  return landmark_graph
end
