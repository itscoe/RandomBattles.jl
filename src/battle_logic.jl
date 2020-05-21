using Distributions, JSON, StaticArrays, Setfield

const possible_decisions = 24

function get_possible_decisions(state; allow_nothing = false)
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

function play_decision(state, decision)
    next_state = state
    if iseven(decision)
        next_state = @set next_state.teams[next_state.agent].shielding = true
    else
        next_state = @set next_state.teams[next_state.agent].shielding = false
    end
    if 1 <= decision <= 2
        next_state = do_nothing(state)
    elseif decision <= 4
        next_state = do_fast_move(state)
    elseif decision <= 6
        next_state = do_charged_move(state, 1)
    elseif decision <= 8
        next_state = do_charged_move(state, 2)
    elseif decision <= 10
        next_state = do_unforced_switch(state, 1)
    elseif decision <= 12
        next_state = do_unforced_switch(state, 2)
    elseif decision <= 14
        next_state = do_unforced_switch(state, 3)
    elseif decision <= 16
        next_state = do_forced_switch(state, 1)
    elseif decision <= 18
        next_state = do_forced_switch(state, 2)
    elseif decision <= 20
        next_state = do_forced_switch(state, 3)
    elseif decision <= 22
        next_state = do_fast_move(state)
        next_state = do_charged_move(next_state, 1)
    elseif decision <= 24
        next_state = do_fast_move(state)
        next_state = do_charged_move(next_state, 2)
    end

    return next_state
end

function play_battle(initial_state::State)
    state = initial_state
    while true
        weights = get_possible_decisions(state)
        weights[9:14] /= 2
        if sum(weights) == 0
            break
        end
        weights /= sum(weights)
        decision = rand(Categorical(weights))
        state = play_decision(state, decision, switchTo)
        if state.agent == 1
            state = @set state.switchPending = SwitchAction(0, 0)
            state = @set state.chargedMovePending = ChargedAction(
                Move(0, 0.0, 0, 0, 0, 0.0, 0, 0, 0, 1),
                0,
            )
            state = @set state.teams[1].shielding = rand(Bool)
            state = @set state.teams[2].shielding = rand(Bool)
        end
    end
    return get_battle_score(state)
end

function get_battle_scores(initial_state::State, N)
    scores = zeros(N)
    for i = 1:N
        scores[i] = play_battle(initial_state)
    end
    return scores
end;
