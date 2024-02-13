export and_or_landmark_extraction
using SymbolicPlanners

"""
extract landmarks by creating an and/or graph and 
"""
function and_or_landmark_extraction(domain::Domain, problem::Problem)
  (nodes, edges, goal_idxs) = build_and_or(domain, problem)

  landmarks_per_node = gen_landmarks(nodes, edges)

  node_count = size(nodes)
  n_goals = size(goal_idxs)
  goal_landmarks = landmarks_per_node[goal_idxs]
  #show(goal_landmarks)
  landmark_count = size(unique(Base.Flatten(landmarks_per_node[goal_idxs])))

  return (node_count , landmark_count, n_goals)
end
#TODO use 'in' instead of contains or weird shit


###build AND/OR graph : nodes types I, OR, AND
#create and or (and keep track of ordering of nodes in pgraph?)
function build_and_or(domain::Domain, problem::Problem)
  #TODO inspect; what does pgraph give me that i cant take from PDDL.jl?-> all actions with pre/post conds?
  #TODO wasnt there a 'build relaxed planning graph?'
  initial_state = initstate(domain, problem)
  spec = Specification(problem)
  pgraph::PlanningGraph = build_planning_graph(domain, initial_state, spec)
  #TODO is julia convention: keep or remove types?  -> ive put them to inspect structs but idk if better or worse
  #TODO conv tuples to structs -> because keeping track of f[1], f[2] is asss
  #get actions, facts, inital states from probelm data

  #todo remove unnesc structs 
  all_facts::Vector{Term} = pgraph.conditions
  all_actions::Vector{GroundAction} = pgraph.actions

  initial_fact_idxs = pgraph_init_idxs(pgraph, domain, initial_state)
  initial_facts = pgraph.conditions[initial_fact_idxs]

  goal_og_idxs = map(x -> x[1],  pgraph.act_parents[end]) #TODO this is flatten but awful

  # nodes + edges representaion
  # node : [originial index in pgraph representation, value/info of action or term, string repr of and/or/i]
  # edges : [from , to] -> indexes in node set

  nodes = Vector() 
  edges_to_child = Vector()
  edges_to_pred = Vector()
  
  # create sets I , AND, OR from prev sets #TODO -> these are just maps?
      
      #I = initial facts 
      for (i,f) in enumerate(initial_facts) # TODO i doesnt make any sense here -> doesnt ref og facts
        push!(nodes, (-1, f, "I")) #TODO -> -1 is bogus
        push!(edges_to_child, Vector{Int}()) 
        push!(edges_to_pred, Vector{Int}()) 
      end

      #traverse facts -> add or nodes
      for (i,f) in enumerate(all_facts)
        if isnothing(findfirst( x -> x[2] == f, nodes))  #TODO use of findfirst is ass here
          push!(nodes, (i, f, "OR"))
          push!(edges_to_child,  Vector{Int}())
          push!(edges_to_pred, Vector{Int}()) 
        end
      end
      
      #traverse all actions -> add and nodes + connections to or nodes

      for (action_i, a::GroundAction) in enumerate(all_actions)

        #if no op ->  -> is made to represent a variable that doesnt change in some representations
        #TODO -> pre and post are both compund terms, do these need to be broken up or is it magically consistent with fact set? -> assuming its fine
        
        #add nodes
        push!(nodes, (action_i, a, "AND"))

        node_i = lastindex(nodes)

        push!(edges_to_child, Vector{Int}())
        push!(edges_to_pred, Vector{Int}()) 

        #get pre and post tems
        pre_conds::Term = PDDL.get_precond(a)   # term = name & args
        post_effs::Term = PDDL.get_effect(a)
        # add edges
        # edge (fact -> action) if in precondition of action
        for pre in pre_conds.args
          fact_i = findfirst( x -> x[2] == pre, nodes)
          if fact_i !== nothing
            push!(edges_to_child[fact_i], node_i)
            push!(edges_to_pred[node_i], fact_i)

          end
        end

        # edge (action -> fact) if in add effect
        for post in post_effs.args #TODO code duplic
          if post.name !== :not # skip if 'not' term -> delete effect represented by 'not' term
            fact_i = findfirst( x -> x[2] == post, nodes)
            if fact_i !== nothing 
              push!(edges_to_child[node_i], fact_i)
              push!(edges_to_pred[fact_i], node_i)  
            end
          end
        end
      end

    #gen goals #TODO this is a strange workaround to bad data structs
    goal_idxs = Vector()
    for (i , n) in enumerate(nodes)
      if n[3] == "OR" && (n[1] in goal_og_idxs)
        push!(goal_idxs, i )
      end
    end

    return (nodes, edges_to_pred, goal_idxs)
end

#TODO : check if landmark graph has nescesary properties named in paper -> should be a justifixcation 
function assertDisjunctiveGraphSets(nodes::Vector, edges::Vector)

  """
    1) all nodes must be proven?
    2) AND nodes are true if all predecessors are true
    3) OR oned are ture if a predecessor is true
    4) subgraph is acyclic
  """
end

function gen_landmarks(nodes::Vector, edges::Vector) 
  # traverse graph untill fixpoint: gives landmark set
  landmarks = Vector()

  #avoid recurision and overflow -> keep list of landmarks per node & do fixppiont -> iterate untill landmarks dont change or 100x iterations
  # initialize all nodes have all nodes as landmarks 
  lms_per_node = Vector()
  
  # initialize as all nodes have all nodes as landmarks 
  #landmarks are tracked as indexes of nodes, extracted later -> not bit vector as union funct needs to work ()
  for i in range(1, lastindex(nodes))
    push!(lms_per_node, collect(range(1, lastindex(nodes))))
  end
  refills = 0
  #init traversal queue #TODO ugly
  nodes_left = Vector()
  for x::Int64 in range(1, lastindex(nodes)) 
    push!(nodes_left, x)
  end

  #update untill fixpoint reached
  while true
          idx_curr = popfirst!(nodes_left)

          #temp for fixpoint check
          temp_lms_per_node = copy(lms_per_node)
          curr_node = nodes[idx_curr]

        #cases by node type
          temp_lms_per_node[idx_curr] = []
          # Init node's landmark is itself
          if curr_node[3] == "I"
            temp_lms_per_node[idx_curr] = [idx_curr]
          #Or node's landmark is intersection of all its preconditions landmarks and itself
          elseif curr_node[3] == "OR"

            for pred_i in edges[idx_curr]
              temp_lms_per_node[idx_curr] = intersect!(temp_lms_per_node[idx_curr], temp_lms_per_node[pred_i])
            end   
            temp_lms_per_node[idx_curr] = union!(temp_lms_per_node[idx_curr], [idx_curr])
          #And node's landmark is union of all its preconditions landmarks and itself
          elseif curr_node[3] == "AND"

            for pred_i in edges[idx_curr]
              temp_lms_per_node[idx_curr] = union!(temp_lms_per_node[idx_curr], temp_lms_per_node[pred_i])
            end
            temp_lms_per_node[idx_curr] = union!(temp_lms_per_node[idx_curr], [idx_curr])
          end



          #stop of fixpoint reached
           if temp_lms_per_node == lms_per_node && refills > 3
              println("\t\t\t fixpoint stopped at ", refills, " refills, \n\t\t\t\tat node: ", idx_curr , " -> " , nodes[idx_curr][3])
              break
           elseif isempty(nodes_left)
            #refill with non init nodes because these will always have themself as landmarks -> breaks alg early
              for x::Int64 in range(1, lastindex(nodes)) 
                if nodes[x][3] !== "I"                 push!(nodes_left, x)
                end 
              end
              refills = refills +1 #TODO remove
           end

          

          lms_per_node = temp_lms_per_node
          # if size(nodes_left) == 0
          #   break
          # end
          # lms_per_node = temp_lms_per_node

  end  
  #TODO lms per node => lms of goals
  
  lm_type_count = Vector()
  for  lms in lms_per_node
    push!(landmarks, map(x-> nodes[x][2] , lms))
    #landmarks_as_types = map(x-> show(x) , map(x-> typeof(nodes[x][2]), lms))
    #print(landmarks_as_types)
    # n_action_lm = filter(x -> (nodes[x][2]) == GroundAction, lms)
    # n_fact_lm = filter(x -> typeof(nodes[x][2]) == Term, lms)
    # push!(lm_type_count, ("fact_lms" =>n_fact_lm , "action_lms" => n_action_lm) )
  end

  # n_action_lms = length(matchtype(GroundAction))
  # n_fact_lms = length(matchtype(Term))

  return (landmarks)
  
end
