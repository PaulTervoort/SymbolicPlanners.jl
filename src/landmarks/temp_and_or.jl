export and_or_landmark_extraction
using SymbolicPlanners

"""
extract landmarks by converting plangraph to an and/or graph
"""

  # struct andOrGraphs
  #   nodes
  #   childindeces
  #   initialsNodes
  #   AndNodes
  #   OrNodes
  # end


  @enum node_type AND=1 OR=2 init=3

  struct andOr_edge
    from::Int
    to::Int
  end
  #TODO edge list very easy -> redo if impl fixpoint becomes easier
  # nodes = [node]
  # out edge per node = [int]
  # in edge per node = [int] -> redundant but should make landmark finding easier

  struct andOr_node
    og_index::Int #is this even nesc?
    term::Any #TODO putting any is bad, is having term even nescesary? -> yes because we need to know what the actual landmark is.
    type::node_type
    parents::Vector[Int]
  end



function and_or_landmark_extraction(domain::Domain, problem::Problem)
  println("start and or extraction")

  

  println("start building graph")
  and_or = build_and_or(domain, problem)

  println("start landmark generation")
  landmark_graph = compute_fixpoint(and_or)

  #check solution?
  #goals = pgraph.act_parents[end]

  #build AND/OR graph : nodes I, OR, AND
  #assign vals untill fixpoint is found
  #write check_fixpoint()

  return landmark_graph
end





###build AND/OR graph : nodes types I, OR, AND
#create and or (and keep track of ordering of nodes in pgraph?)
function build_and_or(domain::Domain, problem::Problem)
  #TODO inspect; what does pgraph give me that i cant take from PDDL.jl?-> all actions with pre/post conds?
  #TODO wasnt there a 'build relaxed planning graph?'
  initial_state = initstate(domain, problem)
  spec = Specification(problem)
  pgraph::PlanningGraph = build_planning_graph(domain, initial_state, spec)
  #TODO is julia convenrion: keep or remove types?  -> ive put them to inspect structs but idk if better or worse
  #TODO conv tuples to structs -> because keeping track of f[1], f[2] is asss
  #get actions, facts, inital states from probelm data
  all_facts::Vector{Term} = pgraph.conditions
  all_actions::Vector{GroundAction} = pgraph.actions
  initial_fact_idxs = pgraph_init_idxs(pgraph, domain, initial_state)
  initial_facts = pgraph.conditions[initial_fact_idxs]

  # nodes + edges representaion
  # node : [originial index in pgraph representation, value/info of action or term, string repr of and/or/i]
  # edges : [from , to] -> indexes in node set

  nodes = Vector() #Tuple{Int, Any, String}
  edges = Vector() #Tuple{Int, Int}
  
  # create sets I , AND, OR from prev sets #TODO -> these are just maps?
      
      #I = initial facts 
      i_set = Vector{Tuple{Int, Term, String}}() #TODO nesc?
      for (i,f) in enumerate(initial_facts) # TODO i doesnt make any sense here -> doesnt ref og facts
        push!(i_set, (i, f, "I"))
        push!(nodes, (i, f, "I"))
      end

      #traverse facts -> add or nodes
      or_set = Vector{Tuple{Int, Term, String}}()  #TODO nesc?
      for (i,f) in enumerate(all_facts)
        if isnothing(findfirst( x -> x[2] == f, nodes))  #TODO use of findfirst is ass here
          push!(or_set, (i, f, "OR"))
          push!(nodes, (i, f, "OR"))

        end
      end
      
      #traverse all actions -> add and nodes + connections to or nodes
      and_set = Vector{Tuple{Int, Term, String}}()  #TODO nesc?
      for (action_i, a::GroundAction) in enumerate(all_actions)

        #if no op ->  -> is made to represent a variable that doesnt change in some representations
        #TODO -> pre and post are both compund terms, do these need to be broken up or is it magically consistent with fact set? -> assuming its fine
        
        #add nodes
        push!(and_set, (action_i, a, "AND"))
        push!(nodes, (action_i, a, "AND"))
        node_i = lastindex(nodes)

        #get pre and post tems
        pre_conds::Term = PDDL.get_precond( a)   # term = name & args
        post_effs::Term = PDDL.get_effect( a)
        # add edges
        # (fact -> action) if in precondition of action
        for pre in pre_conds.args
          fact_i = findfirst( x -> x[2] == pre, nodes)
          if fact_i !== nothing
            push!(edges, (fact_i, node_i)) 

          end
        end
        # (action -> fact) if in effect
        # TODO do not add link if it is a delete effect
        for post in post_effs.args #TODO code duplic
          if post.name !== :not # skip if 'not' term -> delete effect represented by 'not' term
            fact_i = findfirst( x -> x[2] == post, nodes)
            if fact_i !== nothing 
              push!(edges, (node_i, fact_i)) 
            end
          end
        end
      end

    return (nodes, edges)
end

#TODO : check if landmark graph has nescesary properties named in paper -> should be a justifixcation 
function assertDisjunctiveGraphSets()
  """
    1) all nodes must be proven?
    2) AND nodes are true if all predecessors are true
    3) OR oned are ture if a predecessor is true
    4) subgraph is acyclic
  """
end

function compute_fixpoint(pgraph) 


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
    concl: updating in order of plangraph gives same alg? -> maybe later -> can we say order is implicit because we generate graph from plangraph?
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
