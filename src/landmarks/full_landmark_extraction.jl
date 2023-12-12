export full_landmark_extraction

function full_landmark_extraction(domain::Domain, problem::Problem)
    
    # Initialize state and specification
    start_state = initstate(domain, problem)
    spec = Specification(problem)

    # Compute landmark graph
    landmark_graph = compute_landmark_graph(domain, start_state, spec)
    
    # Extract landmarks from landmark graph
    landmarks = Set{Landmark}()

    for landmark_node in landmark_graph.nodes
        landmarks.add(landmark_node.landmark)    
    end

    # Propagate landmarks
    propagated_landmarks = propagate_landmarks(landmark_graph)

    # Merge initial and propagated landmarks
    landmarks = union!(landmarks, propagated_landmarks)




    # Verify that all nodes are actual landmarks
    # Landmarks are verified by checking if the goals are reachable if the landmark is removed from the delete list of the actions leading to them
    # If the goals are reachable, the landmark is not a landmark and is removed from the set of landmarks
    # If the goals are not reachable, the landmark is a landmark and is added to the set of landmarks
    verified_landmarks = verify_landmarks(landmarks, domain, problem)


    # Compute disjunctive landmarks using the verified landmarks

    disjuctive_landmarks = compute_disjunctive_landmarks(verified_landmarks, domain, problem)

    
    # Compute dependency orders of landmarks

    verified_landmarks = union!(verified_landmarks, disjuctive_landmarks)

    return verified_landmarks
    
end



function propagate_landmarks(landmark_graph::LandmarkGraph)

end




function verify_landmarks(landmarks::Set{Landmark}, domain::Domain, problem::Problem)

    # Initialize state and specification
    state = initstate(domain, problem)
    spec = Specification(problem)

    # Initialize planner
    planner = AStarPlanner(HAdd(), save_search=true)

    for landmark in landmarks
        # Remove preconditions of landmark from the delete list of the total action list.
        # This is done by creating a new domain with the modified delete lists
        domain = modify_domain(domain, landmark)

        # Run planner
        sol = planner(domain, state, spec)

        # If no solution is found then it is a landmark
        if sol.status == -1
            continue
        else
            # A solution was found, meaning current landmark is not a landmark in the domain
            delete!(landmarks, landmark)
        end

    end

    return landmarks

end


# Need to wait for paper to include this
function compute_disjunctive_landmarks(landmarks::Set{Landmark}, domain::Domain, problem::Problem) 

    

end

function modify_domain(domain::Domain, landmark::Landmark)

    # Create new domain
    new_domain = deepcopy(domain)

    # Modify delete lists of actions
    for action in new_domain.actions
        delete!(action.delete_list, landmark.preconditions)
    end

    return new_domain

end
