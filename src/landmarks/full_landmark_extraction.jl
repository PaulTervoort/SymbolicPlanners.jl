export full_landmark_extraction

function full_landmark_extraction(domain::Domain, problem::Problem)
    
    # Initialize state and specification
    start_state = initstate(domain, problem)
    spec = Specification(problem)

    # Compute landmark graph
    (landmark_graph, planning_graph) = compute_landmark_graph(domain, start_state, spec)
    
    # Extract landmarks from landmark graph
    landmarks = Set{Landmark}()

    for landmark_node in landmark_graph.nodes
        push!(landmarks, landmark_node.landmark)    
    end

    # Propagate landmarks
    propagated_landmarks = compute_propagation(planning_graph)

    # Merge initial and propagated landmarks
    # landmarks = union!(landmarks, propagated_landmarks)




    # Verify that all nodes are actual landmarks
    # Landmarks are verified by checking if the goals are reachable if the landmark is removed from the delete list of the actions leading to them
    # If the goals are reachable, the landmark is not a landmark and is removed from the set of landmarks
    # If the goals are not reachable, the landmark is a landmark and is added to the set of landmarks
    verified_landmarks = verify_landmarks(landmarks, planning_graph, domain, problem)


    # Compute disjunctive landmarks using the verified landmarks

    # disjuctive_landmarks = compute_disjunctive_landmarks(verified_landmarks, domain, problem)

    
    # Compute dependency orders of landmarks

    # verified_landmarks = union!(verified_landmarks, disjuctive_landmarks)

    return verified_landmarks
    
end



function propagate_landmarks(landmark_graph::LandmarkGraph)

end




function verify_landmarks(landmarks::Set{Landmark}, planning_graph::PlanningGraph, domain::Domain, problem::Problem)

    # Initialize state and specification
    
    spec = Specification(problem)

    # Initialize planner
    planner = AStarPlanner(HAdd(), save_search=true)

    initial_domain = domain

    for landmark in landmarks
        # Remove preconditions of landmark from the delete list of the total action list.
        # This is done by creating a new domain with the modified delete lists
        domain = modify_domain(domain, landmark, planning_graph)

        state = initstate(domain, problem)

        # Run planner
        sol = planner(domain, state, spec)

        # If no solution is found then it is a landmark
        if sol.status == -1
            continue
        else
            # A solution was found, meaning current landmark is not a landmark in the domain
            delete!(landmarks, landmark)
        end

        domain = initial_domain

    end

    return landmarks

end


# Need to wait for paper to include this
function compute_disjunctive_landmarks(landmarks::Set{Landmark}, domain::Domain, problem::Problem) 

    

end

function modify_domain(domain::Domain, landmark::Landmark, planning_graph::PlanningGraph)

    
    new_actions = Set{Symbol}()

    # Find all actions that dont add the landmark

    for fact in landmark.facts
        # Retrieve the name of the action e.g. "stack"
        curr_action = planning_graph.actions[fact.var].name
        push!(new_actions, curr_action)
    end

    # for action in domain.actions
    #     # Get name of action 
    #     if action.first in new_actions
    #         continue
    #     else
    #         # Remove all the delete actions (negative effects) by checking if a negation is happening
    #         filter!(x -> x.name != Symbol("not"), action.second.effect.args)
    #     end
    # end

    # Go over add list of actions. If the landmark is in the add list, remove the delete list from that action
    for curr_action in new_actions

        # Go over all actions in the domain
        for action in domain.actions
            # Get name of actions in actions add list
            action_names = map(x -> x.name, action.second.effect.args)
            if curr_action in action_names
                filter!(x -> x.name != Symbol("not"), action.second.effect.args)
            end
        end
    end


    return domain

end
