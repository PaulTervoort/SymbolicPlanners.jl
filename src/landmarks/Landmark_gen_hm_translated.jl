hm_generation(task){
    compute_h_m_landmarks(task)
    
}



function compute_h_m_landmarks(task_proxy)
    init_subsets = get_subsets_for_m(task_proxy.variables, m, task_proxy.initial_state)
    
    current_actions = Dict()
    next_actions = Dict()

    for subset in init_subsets
        index = get_index_for_subset(subset)
        h_m_table[index].level = 0
        mark_actions_for_execution(index, true, current_actions)
    end

    for action in pm_ops
        if unsatisfied_precondition_count(action) == 0
            current_actions[action] = Set()
        end
    end

    local_landmarks = Set()
    local_necessary = Set()
    previous_landmarks_size = 0
    level = 1

    while !isempty(current_actions)
        for action_index in keys(current_actions)
            local_landmarks = Set()
            local_necessary = Set()
            action = pm_ops[action_index]

            for precondition in action.preconditions
                local_landmarks = union(local_landmarks, h_m_table[precondition].landmarks)
                push!(local_landmarks, precondition)

                if use_orders
                    push!(local_necessary, precondition)
                end
            end

            for effect in action.effects
                if h_m_table[effect].level != -1
                    previous_landmarks_size = length(h_m_table[effect].landmarks)
                    h_m_table[effect].landmarks = intersect(h_m_table[effect].landmarks, local_landmarks)

                    if !(effect in local_landmarks)
                        push!(h_m_table[effect].first_achievers, action_index)
                        if use_orders
                            h_m_table[effect].necessary = intersect(h_m_table[effect].necessary, local_necessary)
                        end
                    end

                    if length(h_m_table[effect].landmarks) != previous_landmarks_size
                        mark_actions_for_execution(effect, false, next_actions)
                    end
                else
                    h_m_table[effect].level = level
                    h_m_table[effect].landmarks = copy(local_landmarks)
                    if use_orders
                        h_m_table[effect].necessary = copy(local_necessary)
                    end
                    push!(h_m_table[effect].first_achievers, action_index)
                    mark_actions_for_execution(effect, true, next_actions)
                end
            end

            if isempty(current_actions[action_index])
                for i in 1:length(action.conditional_noops)
                    if unsatisfied_precondition_count(action_index, i) == 0
                        compute_noop_landmarks(action_index, i, local_landmarks, local_necessary, level, next_actions)
                    end
                end
            else
                for noop_index in current_actions[action_index]
                    assert(unsatisfied_precondition_count(action_index, noop_index) == 0)
                    compute_noop_landmarks(action_index, noop_index, local_landmarks, local_necessary, level, next_actions)
                end
            end
        end

        current_actions = copy(next_actions)
        next_actions = Dict()

        if log_is_at_least_verbose()
            println("Level $level completed.")
        end

        level += 1
    end

    if log_is_at_least_normal()
        println("h^m landmarks computed.")
    end
end
