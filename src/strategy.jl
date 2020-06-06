mutable struct DecisionMatrix
    decision_matrix::Array{Tuple{Float64,Float64},2}
end

function DecisionMatrix()
    dmat = Array{Tuple{Float64,Float64}}(
        undef,
        possible_decisions,
        possible_decisions,
    )
    for i = 1:possible_decisions, j = 1:possible_decisions
        dmat[i, j] = (1.0, 0.0)
    end
    return DecisionMatrix(dmat)
end

function get_decision_matrix(state; battles_per_turn = 1000)
    d_matrix = DecisionMatrix()
    weights1 = get_possible_decisions(state)
    weights2 = get_possible_decisions(switch_agent(state))
    if !iszero(sum(weights1)) && !iszero(sum(weights2))
        for d1 in findall(isone, weights1), d2 in findall(isone, weights2)
            next_state = play_turn(state, (d1, d2))
            scores = get_battle_scores(next_state, battles_per_turn)
            d_matrix.decision_matrix[d1, d2] = (minimum(scores), maximum(scores))
        end
    end
    return d_matrix
end

function minimax(dmat::DecisionMatrix)
    mins = ones(possible_decisions)
    for i = 1:possible_decisions, j = 1:possible_decisions
        if first(dmat.decision_matrix[i, j]) < mins[i]
            mins[i] = first(dmat.decision_matrix[i, j])
        end
    end
    replace!(mins, 1.0 => 0.0)
    minimax = argmax(mins)
    maxes = zeros(possible_decisions)
    for i = 1:possible_decisions, j = 1:possible_decisions
        if last(dmat.decision_matrix[i, j]) > maxes[j]
            maxes[j] = last(dmat.decision_matrix[i, j])
        end
    end
    replace!(maxes, 0.0 => 1.0)
    maximin = argmin(maxes)
    return (minimax, maximin)
end

function is_empty(dmat::DecisionMatrix)
    return dmat.decision_matrix == DecisionMatrix().decision_matrix
end

mutable struct Strategy
    decisions::Array{Tuple{Int64,Int64}}
    minimaxes::Array{Tuple{Float64,Float64}}
end

Strategy() = Strategy([], [])

function Strategy(state::State; battles_per_turn::Int64 = 1000)
    strategy = Strategy()
    current_state = state
    while true
        d_matrix = get_decision_matrix(current_state, battles_per_turn = battles_per_turn)
        is_empty(d_matrix) && return strategy
        decision = minimax(d_matrix)
        push!(strategy.decisions, decision)
        push!(
            strategy.minimaxes,
            d_matrix.decision_matrix[decision[1], decision[2]],
        )
        current_state = play_turn(current_state, decision)
    end
end
