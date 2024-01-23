using Graphs
using MetaGraphs

#todo : replace with number of initial nodes
vi = 4 ;

g = SimpleDirGraph(vi);

h = MetaGraph(
    SimpleDirGraph(vi);  # underlying graph structure
    label_type=Symbol,  # label : AND / OR/ INIT
)

another_g = MetaDiGraph(g, 3.0)

# we have to turn the plangraph into AND/OR in doing this we can can remove delete nodes (no need to make delete relax only for me)
# -> double check if KA has made delete relaxation


#OPTIONS :
# graph -> metagrph -> add data         or      metagrph -> add nodes + data in one go
# second seems better but we'll see

struct andOrGraphs
    nodes
    childindeces
    initialsNodes
    AndNodes
    OrNodes
end

# add_vertex!(g) adds one vertex to g
# add_vertices!(g, n) adds n vertices to g
# add_edge!(g, s, d) adds the edge (s, d) to g
# rem_vertex!(g, v) removes vertex v from g
# rem_edge!(g, s, d) removes edge (s, d) from 


# AND /OR grpah 
# -> is  a drected graph with
# -> I(nitial) nodes, AND nodes, OR nodes

# -> for every fact f, every action a
# -> a becomes an and node
# -> f becomes an or node

# -> add edge (a -> f) if f is in add(a)
# -> add edge (f -> a) if  f is in pre(a)

#impl by traversing a's and adding connections


# -> you can then see a planning solution as subgraph describing 'do this' AND 'do this' AND 'do this' . the set of possible facts being do this or do tis or do this


# -> formatted using JuliaFormatter
# -> style of https://github.com/invenia/BlueStyle


# PLOT https://juliagraphs.org/Graphs.jl/dev/first_steps/plotting/




## create own graph: https://juliagraphs.org/Graphs.jl/dev/ecosystem/interface/