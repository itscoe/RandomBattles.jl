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
        3  || 4  => fast_move(next_state)
        5  || 6  => queue_charged_move(next_state, 1)
        7  || 8  => queue_charged_move(next_state, 2)
        9  || 10 => queue_switch(next_state, 1)
        11 || 12 => queue_switch(next_state, 2)
        13 || 14 => queue_switch(next_state, 3)
        15 || 16 => queue_switch(next_state, 1, time = 12_000)
        17 || 18 => queue_switch(next_state, 2, time = 12_000)
        19 || 20 => queue_switch(next_state, 3, time = 12_000)
        21 || 22 => queue_charged_move(fast_move(next_state), 1)
        23 || 24 => queue_charged_move(fast_move(next_state), 2)
        _        => next_state
    end

    return next_state
end

function play_battle(initial_state::State)
    state = initial_state
    while true
        weights = get_possible_decisions(state)
        weights[9:14] /= 2
        iszero(sum(weights)) && return get_battle_score(state)
        decision = rand(Categorical(weights / sum(weights)))
        state = play_decision(state, decision)
        state = @set state.agent = get_other_agent(state.agent)

        weights = get_possible_decisions(state)
        weights[9:14] /= 2
        iszero(sum(weights)) && return get_battle_score(state)
        decision = rand(Categorical(weights / sum(weights)))
        state = play_decision(state, decision)
        state = @set state.agent = get_other_agent(state.agent)

        state = evaluate_charged_moves(state)
        state = reset_charged_moves_pending(state)
        state = evaluate_switches(state)
        state = reset_switches_pending(state)
        state = step_timers(state)
    end
end

function get_battle_scores(initial_state::State, N::Int64)
    scores = zeros(N)
    for i = 1:N
        scores[i] = play_battle(initial_state)
    end
    return scores
end;
