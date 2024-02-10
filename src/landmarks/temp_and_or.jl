export and_or_landmark_extraction
using SymbolicPlanners

"""
TEMP TEMP TEMP THIS IS COPIED! -> from ka
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

extract landmarks by converting plangraph to an and/or graph
"""
struct andOrGraphs
  nodes
  childindeces
  initialsNodes
  AndNodes
  OrNodes
end

#TODO tyoe of node should be implcit by position in tree -> init is fact, child is action, child is faact...
@enum andOR_node_type AND=1 OR=2 I=3

# struct andOr_node
#   index::Int
#   type::andOR_node_type
#   parents::Vector[Int] #nesc?
#   and_children::Vector[Int] #refs prgraph actions
#   or_children::Vector[Int] #refs prgraph conditions
# end



function and_or_landmark_extraction(domain::Domain, problem::Problem)
  println("start and or extraction")
  initial_state = initstate(domain, problem)
  spec = Specification(problem)

  pgraph::PlanningGraph = build_planning_graph(domain, initial_state, spec)

  
  and/or = build_and_or(pgraph, domain, problem)

  goals = pgraph.act_parents[end]
  


println("start building graph")
##    #build AND/OR graph : nodes types I, OR, AND
  
  #TODO is julia convenrion: keep or remove types?  -> ive put them to inspect structs but idk if better or worse
  #TODO conv tuples to structs -> because keeping track of f[1], f[2] is asss
  #get actions, facts, inital states from probelm data
  all_facts::Vector{Term} = pgraph.conditions
  all_actions::Vector{GroundAction} = pgraph.actions
  initial_fact_idxs = pgraph_init_idxs(pgraph, domain, initial_state)
  initial_facts = pgraph.conditions[initial_fact_idxs]

  #nodes + edges representaion
  # node : [originial index in pgraph representation, value/info of action or term, string repr of and/or/i]
  # edges : [from , to] -> indexes in node set

  node_set = Vector() #Tuple{Int, Any, String}
  edge_set = Vector() #Tuple{Int, Int}
  
  # create sets I , AND, OR from prev sets #TODO -> these are just maps
      
      #I = initial facts 
      i_set = Vector{Tuple{Int, Term, String}}() #TODO nesc?
      for (i,f) in enumerate(initial_facts) # i doesnt make any sense here -> doesnt ref og facts
        push!(i_set, (i, f, "I"))
        push!(node_set, (i, f, "I"))
        print("\t\tadded I")
      end

      #traverse facts -> add or nodes
      or_set = Vector{Tuple{Int, Term, String}}()  #TODO nesc?
      for (i,f) in enumerate(all_facts)
        push!(or_set, (i, f, "OR"))
        push!(node_set, (i, f, "OR"))
        print("\t\tadded O")
      end
      
      #traverse all actions -> add and nodes + connections to or nodes
      and_set = Vector{Tuple{Int, Term, String}}()  #TODO nesc?
      for (i, a::GroundAction) in enumerate(all_actions)

        #if no op ->  -> is made to represent a variable that doesnt change in some representations
        #TODO -> pre and post are both compund terms, do these need to be broken up or is it magically consistent with fact set? -> assuming its fine
        
        #add nodes
        push!(and_set, (i, a, "AND"))
        push!(node_set, (i, a, "AND"))
        print("\t\tadded A")

        #get pre and post tems
        pre::Term = PDDL.get_precond( a) # name & args
        post::Term = PDDL.get_effect( a)
        # add edges
        # (action -> fact) if in effect
        # (fact -> action) if in precondition of action
        for f in i_set 
          if occursin(f[2] , pre.args)
            push!(edge_set, (f[1], i))
            print("\t\tadded E")
          end
          if f[2] == post
            push!(edge_set, (i, f[1]))
            print("\t\tadded E")
          end
        end

        for f in or_set #TODO code duplication last block
          if f[2] == pre
            push!(edge_set, (f[1], i))
            print("\t\tadded E")
          end
          if f[2] == post
            push!(edge_set, (i, f[1]))
            print("\t\tadded E")
          end
        end

      end

    #and or is now node set + edge set
    println("\ngenerated graph:\n\n")
    println("\n\tnodes: " , node_set)
    println("\n\tedges: ", edge_set)


  #get set of facts from landmark graph :: TODO  this is ass -> they got it from pgraphs conditions??
  #var in FactPair refers to condition in pgraph.conditions -> useless without pgraph.conditions
  landmark_graph_data::LandmarkGenerationData, landmark_graph::LandmarkGraph = compute_relaxed_landmark_graph(domain, initial_state, spec).first
  i_state::Vector{FactPair} = landmark_graph_data.initial_state
  



  #build AND/OR graph : nodes I, OR, AND
  #assign vals untill fixpoint is found
  #write check_fixpoint()


  landmark_graph = compute_fixpoint(and/or)

  return landmark_graph
end


#create and or and keep track of ordering of nodes in pgraph
function build_and_or(pgraph::PlanningGraph, domain::Domain, problem::Problem)
  # find init nodes, action set, state var set TODO: nesc?
  init_idxs = pgraph_init_idxs(pgraph, domain, initial_state)
  # as = pgraph.actions
  # fs = pgraph.conditions


  #STRIPS INFO : actions, facts, initial states,goal states
  as = PDDL.get_actions(domain)
  fs = PDDL.get_fluents(domain) #problem: fluents are functions? this is ok as they are unnasigned state vars :P -> NO! facts are predicates, terms are anything
  #TODO: get facts from compute_landmark_graph -> get all facts from set and init to 0? -> gives set of facts. facts in I can be 1
  
  is = PDDL.get_init_terms(problem) # a term is an assigned fluent or constant?
  gs = PDDL.get_goal(problem)
  
  # create sets I , AND, OR from prev sets
  


  #traverse facts -> add or nodes
  #traverse action -> add and nodes + connections to or nodes

  #  add edges by traversing actions
  # (action -> fact) if in effect
  # (fact -> action) if in precondition of action
end

function compute_fixpoint(pgraph) 
  #build graph : nodes I, OR, AND

  "from paper
          One way to
          compute the solution is to perform a ﬁxpoint computation in which
          the set of landmarks for each vertex except those in VI is initialized
          to the set of all of the vertices of the graph G and then iteratively
          updated by interpreting the equations as update rules. If the updates
          are performed according to the order in which nodes are generated in
          the relaxed planning graph (i. e., all nodes in the ﬁrst layer, then all
          nodes in the second layer, etc.), then we obtain exactly the RPG label
          propagation algorithm by Zhu & Givan [12], computing action land-
          marks as well as causal fact landmarks. If only fact landmarks are
          sought, the equation for AND nodes can be modiﬁed to not include
          {v} in LM(v).
    concl: updating in order of plangraph gives same alg? -> maybe later
  "
  # traverse graph untill fixpoint: gives landmark set
  # LM(Vg) = uninion of all returned 
  # 			for v in VG
  # 				 LM(v)
  # this is where plangraph ordering of nodes is important-> calling LM(v) over all nodes. 

  # LM(v) = 
  # 		if v in I
  # 			 -> {v}
  # 		if v in OR
  # 				-> {v} intersect 
  # 						for u in pre(v)
  # 							 LM(u)
  # 		if v in AND
  # 				-> {v} union
  # 						for u in pre(v)
  # 							 LM(u)
                
  # Pre(v) = u for all <u, v> in E -> its a map :)
end

# function generate_landmarks_chatgpt(planning_graph::PlanningGraph, goal)
#   # Initialize landmarks for all nodes
#   landmarks = Dict{Int, Set{Int}}()
#   for i in 1:length(planning_graph.conditions)
#       landmarks[i] = Set([i])
#   end

#   for i in 1:length(planning_graph.actions)
#       landmarks[i + planning_graph.n_goals] = Set([i + planning_graph.n_goals])
#   end

#   # Update landmarks until fixpoint is reached
#   while true
#       updated_landmarks = copy(landmarks)

#       for i in 1:length(planning_graph.conditions)
#           # Update landmarks for condition nodes
#           if !planning_graph.cond_derived[i]
#               parents = get_parents(planning_graph, i)
#               #TODO strange union / intersection thing happening here : ⋂
#               updated_landmarks[i] = Set([i]) ∪ ([landmarks[parent] for parent in parents])
#           end
#       end

#       for i in 1:length(planning_graph.actions)
#           # Update landmarks for action nodes
#           children = planning_graph.act_children[i]
#           #current version breaks here
#           updated_landmarks[i + planning_graph.n_goals] = Set([i + planning_graph.n_goals]) ∪ ([landmarks[child] for child in children])
#       end

#       # Check for fixpoint
#       if updated_landmarks == landmarks 
#           break
#       end

#       landmarks = updated_landmarks
#   end

#   # Return the set of landmarks for the goal node
#   goal_node_index = findfirst(x -> x == goal, planning_graph.conditions)
#   return ∪([landmarks[goal_node_index] for goal_node_index in goal_node_indices])
# end

# function get_parents(planning_graph::PlanningGraph, node_index::Int)
#   parents = Set{Int}()

#   for (i, children) in enumerate(planning_graph.cond_children)
#       if any(x -> x == node_index, children)
#           push!(parents, i)
#       end
#   end

#   return parents
# end
