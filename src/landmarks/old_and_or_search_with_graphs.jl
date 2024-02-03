using Graphs
using MetaGraphs

#todo : replace with number of initial nodes
vi = 4 ;


struct andOrGraphs
    nodes
    childindeces
    initialsNodes
    AndNodes
    OrNodes
end


# AND /OR grpah 
# -> is  a drected graph with
# -> I(nitial) nodes, AND nodes, OR nodes

# -> for every fact f, every action a
# -> a becomes an and node
# -> f becomes an or node

# -> add edge (a -> f) if f is in add(a)
# -> add edge (f -> a) if  f is in pre(a)

#impl by traversing a's and adding connections

function create_and_or(pgraph::PlanningGraph)
    # AND /OR grpah 
    # -> is  a drected graph with
    # -> I(nitial) nodes, AND nodes, OR nodes

    # -> for every fact f, every action a
    # -> a becomes an and node
    as = pgraph.actions
    # -> f becomes an or node
    fs = pgraph.conditions


    # -> add edge (a -> f) if f is in add(a)
    # -> add edge (f -> a) if  f is in pre(a)

    #impl by traversing a's and adding connections
    for a in as 
        #TODO this is just a depth first or breath first tree build with extra conditions
        #how do i get juliagraphs to do this for me?

    end
    

    g = MetaGraph(
    SimpleDirGraph(vi);  # underlying graph structure
    label_type=Symbol,  # color name
    vertex_data_type=NTuple{3,Int},  # RGB code
    edge_data_type=Symbol,  # result of the addition between two colors
    graph_data="additive colors",  # tag for the whole graph
    )

    

end


#function that finds justifying (as defined...) subgraph 
function find_subgraph()

end




# -> you can then see a planning solution as subgraph describing 'do this' AND 'do this' AND 'do this' . the set of possible facts being do this or do tis or do this


# -> formatted using JuliaFormatter
# -> style of https://github.com/invenia/BlueStyle


# PLOT https://juliagraphs.org/Graphs.jl/dev/first_steps/plotting/




## create own graph: https://juliagraphs.org/Graphs.jl/dev/ecosystem/interface/