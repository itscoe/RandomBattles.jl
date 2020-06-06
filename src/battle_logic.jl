using Distributions, Setfield, Match

const possible_decisions = 24

function get_possible_decisions(state::State; allow_nothing = false)
    decisions = zeros(possible_decisions)
    activeTeam = state.teams[state.agent]
    activeMon = activeTeam.mons[activeTeam.active]
    if activeMon.hp > 0
        decisions[1] = 1
        decisions[2] = 1
        if activeMon.fastMoveCooldown == 0
            decisions[3] = 1
            decisions[4] = 1
            if !allow_nothing
                decisions[1] = 0
                decisions[2] = 0
            end
        end
        if activeMon.energy >= activeMon.chargedMoves[1].energy
            decisions[5] = 1
            decisions[6] = 1
        end
        if activeMon.energy >= activeMon.chargedMoves[2].energy
            decisions[7] = 1
            decisions[8] = 1
        end
        for i = 1:3
            if i != activeTeam.active &&
               activeTeam.mons[i].hp != 0 && activeTeam.switchCooldown == 0
                decisions[2*i+7] = 1
                decisions[2*i+8] = 1
            end
        end
        if activeMon.fastMoveCooldown == 0 &&
           activeMon.energy +
           activeMon.fastMove.energy >= activeMon.chargedMoves[1].energy
            decisions[21] = 1
            decisions[22] = 1
        end
        if activeMon.fastMoveCooldown == 0 &&
           activeMon.energy +
           activeMon.fastMove.energy >= activeMon.chargedMoves[2].energy
            decisions[23] = 1
            decisions[24] = 1
        end
    else
        for i = 1:3
            if i != activeTeam.active && activeTeam.mons[i].hp != 0
                decisions[2*i+13] = 1
                decisions[2*i+14] = 1
            end
        end
    end
    return decisions
end

function play_decision(state::State, decision::Int64)
    next_state = state
    if iseven(decision)
        next_state = @set next_state.teams[next_state.agent].shielding = true
    else
        next_state = @set next_state.teams[next_state.agent].shielding = false
    end
    next_state = @match decision begin
        3  || 4  => queue_fast_move(next_state)
        5  || 6  => queue_charged_move(next_state, 1)
        7  || 8  => queue_charged_move(next_state, 2)
        9  || 10 => queue_switch(next_state, 1)
        11 || 12 => queue_switch(next_state, 2)
        13 || 14 => queue_switch(next_state, 3)
        15 || 16 => queue_switch(next_state, 1, time = 12_000)
        17 || 18 => queue_switch(next_state, 2, time = 12_000)
        19 || 20 => queue_switch(next_state, 3, time = 12_000)
        21 || 22 => queue_charged_move(queue_fast_move(next_state), 1)
        23 || 24 => queue_charged_move(queue_fast_move(next_state), 2)
        _        => next_state
    end

    return next_state
end

function play_turn(state::State, decision1::Int64, decision2::Int64)
    next_state = play_decision(state, decision1)
    next_state = @set next_state.agent = get_other_agent(next_state.agent)
    next_state = play_decision(next_state, decision2)
    next_state = @set next_state.agent = get_other_agent(next_state.agent)

    println(next_state.fastMovesPending)

    next_state = evaluate_fast_moves(next_state)
    next_state = evaluate_charged_moves(next_state)
    next_state = evaluate_switches(next_state)
    next_state = reset_queues(next_state)
    next_state = step_timers(next_state)
    return next_state
end

function play_battle(initial_state::State)
    state = initial_state
    while true
        old_state = state

        weights1 = get_possible_decisions(state)
        weights1[9:14] /= 2
        state = @set state.agent = get_other_agent(state.agent)
        weights2 = get_possible_decisions(state)
        weights2[9:14] /= 2
        state = @set state.agent = get_other_agent(state.agent)
        (iszero(sum(weights1)) || iszero(sum(weights2))) && return get_battle_score(state)

        decision1 = rand(Categorical(weights1 / sum(weights1)))
        decision2 = rand(Categorical(weights2 / sum(weights2)))

        state = play_turn(state, decision1, decision2)

        println((decision1, decision2))
        diff(old_state, state)
        println()
    end
end

function get_battle_scores(initial_state::State, N::Int64)
    scores = zeros(N)
    for i = 1:N
        scores[i] = play_battle(initial_state)
    end
    return scores
end;
