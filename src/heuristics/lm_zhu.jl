
include("pgraph.jl")

mutable struct graph_node
  labels::Set{Int}
  graph_node() = new()
end

function deepcopy(node::graph_node)
  new_node = graph_node()
  new_node_labels = deepcopy(node.labels)
  return new_node
end

function deepcopy_vector(vec::Vector{graph_node})
  return [deepcopy(node) for node in vec]
end

function compute_propagation(pgraph::PlanningGraph)
  triggers = Vector{Vector{Int}}()

  n_conditions = length(pgraph.conditions)
  resize!(triggers, n_conditions)

  cond_children = pgraph.cond_children

  for (i, conditions) in enumerate(cond_children)
    for tuple in conditions
      idx_action, idx_precond = tuple
      push!(triggers[i], idx_action)
    end
  end

  return triggers
end

function effect_empty(layer::Vector{graph_node}, effect::Vector{Int})
  for (i, cond) in enumerate act_children
    if (isempty(layer[i].labels))
      return false
    end
  end
  return true
end

function precond_empty(layer::Vector{graph_node}, precond::Vector{Vector{Int}})
  for (i, out) in enumerate(precond)
    for (j, cond) in enumerate(out)
      if (isempty(layer[j].labels))
        return false
      end
    end
  end
    return true
end


function apply_action_and_propagate(layer::Vector{graph_node}, graph::PlanningGraph, action::Int, next_layer::Vector{graph_node})
  result = Set{Int}()

  precond_union = union_preconditions(layer, graph.act_parents[action])

  for (i, effects) in graph.act_children[action]
    if(length(next_layer[i].labels) == 1)
      continue
    end

    if (effect_empty(layer, effects))
      precond_effect = copy(precond_union)
      union!(precond_effect, union_effect(layer, effects))

      if (labels_propagated(next_layer[i].labels, precond_effect,i))
        push(result, i)
      end
    end
  end

  return result
end

function labels_propagated(old_labels::Set{Int}, new_labels::Set{Int}, condition::Int)
  copy_old = copy(old_labels)

  if(!isempty(old_labels))
    old_labels = intersect(old_labels, new_labels)
  else
    old_labels = new_labels
  end

  push!(old_labels, conditions)

  return length(old_labels) != length(copy_old)
end

function union_preconditions(layer::Vector{graph_node}, precond::Vector{Vector{Int}})
  result = Set{Int}()

  for (i, out) in enumerate(precond)
    for (j, cond) in enumerate(out)
      union!(result, layer[i].labels) 
    end
  end
  return result
end

function union_effect(layer::Vector{graph_node}, precond::Vector{Int})
  result = Set{Int}()
  for (i, cond) in enumerate act_children
      union!(result, layer[i].labels) 
  end
  return result
end

function graph_label(pgraph::PlanningGraph, domain::Domain, state::State)

  n_conditions = length(pgraph.conditions)
  triggers = compute_propagation(pgraph)
  
  set = Set()

  init_idxs = pgraph_init_idxs(graph, domain, state)
  prop_layer =  Vector{graph_node}()

  for i in findall(init_idxs)
    push!(prop_layer[i].labels, i)
  end

  for (i, conditions) in pgraph.conditions
    push!(set, triggers[i])
  end

  changes = true

  while(changes)
    next_layer = deepcopy(prop_layer)
    next_trigger = Set()
    changes = false
    for i in triggers
      precond = graph.act_parents[i]
      if (precond_empty(prop_layer, precond))
        changed = apply_action_and_propagate(layer, graph, i, next_layer)

        if (!isempty(changed))
          changes = true
          for j in changed
            push!(next_trigger, triggers[j])
          end
        end
      end
    end
    prop_layer = next_layer
    triggers = next_trigger
  end
  return prop_layer
end

include("pgraph.jl")
