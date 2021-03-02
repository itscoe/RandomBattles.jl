using Distributions, StaticArrays

function get_possible_decisions(state::DynamicState, static_state::StaticState, agent::Int64; allow_nothing = false)
    @inbounds activeTeam = state.teams[agent]
    @inbounds activeMon = activeTeam.mons[activeTeam.active]
    @inbounds activeStaticTeam = static_state.teams[agent]
    @inbounds activeStaticMon = activeStaticTeam.mons[activeTeam.active]
    state.fastMovesPending[agent] != Int8(0) && state.fastMovesPending[agent] != Int8(-1) && activeMon.hp != Int16(0) && return @SVector [1.0,
        1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    @inbounds return @SVector [((allow_nothing || state.fastMovesPending[agent] > Int8(0)) && activeMon.hp > Int16(0)) ? 1.0 : 0.0,
        ((allow_nothing || state.fastMovesPending[agent] > Int8(0)) && activeTeam.shields > Int8(0) && activeMon.hp > Int16(0)) ? 1.0 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeMon.hp > 0) ? 1.0 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeTeam.shields > Int8(0) && activeMon.hp > 0) ? 1.0 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeMon.energy >= activeStaticMon.chargedMoves[1].energy && activeMon.hp > Int16(0)) ? 1.0 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeMon.energy >= activeStaticMon.chargedMoves[1].energy && activeTeam.shields > Int8(0) && activeMon.hp > Int16(0)) ? 1.0 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeMon.energy >= activeStaticMon.chargedMoves[2].energy && activeMon.hp > Int16(0)) ? 1.0 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeMon.energy >= activeStaticMon.chargedMoves[2].energy && activeTeam.shields > Int8(0) && activeMon.hp > Int16(0)) ? 1.0 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeTeam.switchCooldown == Int8(0) && activeTeam.active != Int8(1) && activeTeam.mons[1].hp > Int16(0) && activeMon.hp > Int16(0)) ? 0.5 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeTeam.switchCooldown == Int8(0) && activeTeam.active != Int8(1) && activeTeam.shields > Int8(0) && activeTeam.mons[1].hp > Int16(0) && activeMon.hp > Int16(0)) ? 0.5 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeTeam.switchCooldown == Int8(0) && activeTeam.active != Int8(2) && activeTeam.mons[2].hp > Int16(0) && activeMon.hp > Int16(0)) ? 0.5 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeTeam.switchCooldown == Int8(0) && activeTeam.active != Int8(2) && activeTeam.shields > Int8(0) && activeTeam.mons[2].hp > Int16(0) && activeMon.hp > Int16(0)) ? 0.5 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeTeam.switchCooldown == Int8(0) && activeTeam.active != Int8(3) && activeTeam.mons[3].hp > Int16(0) && activeMon.hp > Int16(0)) ? 0.5 : 0.0,
        (state.fastMovesPending[agent] <= Int8(0) && activeTeam.switchCooldown == Int8(0) && activeTeam.active != Int8(3) && activeTeam.shields > Int8(0) && activeTeam.mons[3].hp > Int16(0) && activeMon.hp > Int16(0)) ? 0.5 : 0.0,
        (activeMon.hp == Int16(0) && activeTeam.mons[1].hp > Int16(0)) ? 1.0 : 0.0,
        (activeMon.hp == Int16(0) && activeTeam.shields > Int8(0) && activeTeam.mons[1].hp > Int16(0)) ? 1.0 : 0.0,
        (activeMon.hp == Int16(0) && activeTeam.mons[2].hp > Int16(0)) ? 1.0 : 0.0,
        (activeMon.hp == Int16(0) && activeTeam.shields > Int8(0) && activeTeam.mons[2].hp > Int16(0)) ? 1.0 : 0.0,
        (activeMon.hp == Int16(0) && activeTeam.mons[3].hp > Int16(0)) ? 1.0 : 0.0,
        (activeMon.hp == Int16(0) && activeTeam.shields > Int8(0) && activeTeam.mons[3].hp > Int16(0)) ? 1.0 : 0.0]
end

function play_turn(state::DynamicState, static_state::StaticState, decision::Tuple{Int64,Int64})
    dec = Decision(decision)
    next_state = state

    if next_state.fastMovesPending[1] == Int8(0)
        next_state = evaluate_fast_moves(next_state, static_state, Int8(1))
    end
    if next_state.fastMovesPending[2] == Int8(0)
        next_state = evaluate_fast_moves(next_state, static_state, Int8(2))
    end

    next_state = step_timers(next_state,
        3 <= decision[1] <= 4 ? static_state.teams[1].mons[next_state.teams[1].active].fastMove.cooldown : Int8(0),
        3 <= decision[2] <= 4 ? static_state.teams[2].mons[next_state.teams[2].active].fastMove.cooldown : Int8(0))

    if dec.switchesPending[1].pokemon != Int8(0)
        next_state = evaluate_switch(next_state, Int8(1), dec.switchesPending[1].pokemon, dec.switchesPending[1].time)
    end
    if dec.switchesPending[2].pokemon != Int8(0)
        next_state = evaluate_switch(next_state, Int8(2), dec.switchesPending[2].pokemon, dec.switchesPending[2].time)
    end

    cmp = get_cmp(next_state, static_state, dec::Decision)
    if cmp[1] != Int8(0)
        next_state = evaluate_charged_moves(next_state, static_state, cmp[1],
            dec.chargedMovesPending[cmp[1]].move, dec.chargedMovesPending[cmp[1]].charge, dec.shielding[get_other_agent(cmp[1])],
            rand(Int8(0):Int8(99)) < static_state.teams[cmp[1]].mons[next_state.teams[cmp[1]].active].chargedMoves[dec.chargedMovesPending[cmp[1]].move].buffChance)
        if next_state.fastMovesPending[get_other_agent(cmp[1])] != Int8(-1)
            next_state = evaluate_fast_moves(next_state, static_state, cmp[1])
        end
    end
    if cmp[2] != Int8(0)
        next_state = evaluate_charged_moves(next_state, static_state, cmp[2],
            dec.chargedMovesPending[cmp[2]].move, dec.chargedMovesPending[cmp[2]].charge, dec.shielding[get_other_agent(cmp[2])],
            rand(Int8(0):Int8(99)) < static_state.teams[cmp[2]].mons[next_state.teams[cmp[2]].active].chargedMoves[dec.chargedMovesPending[cmp[2]].move].buffChance)
        if next_state.fastMovesPending[get_other_agent(cmp[2])] != Int8(-1)
            next_state = evaluate_fast_moves(next_state, static_state, cmp[2])
        end
    end

    return next_state
end

function play_battle(starting_state::DynamicState, static_state::StaticState)
    state = starting_state
    while true
        weights1, weights2 = get_possible_decisions(state, static_state, 1), get_possible_decisions(state, static_state, 2)
        (sum(weights1) * sum(weights2) == 0) && return get_battle_score(state, static_state)
        decision1, decision2 = rand(Categorical(weights1 / sum(weights1))), rand(Categorical(weights2 / sum(weights2)))
        state = play_turn(state, static_state, (decision1, decision2))
    end
end

function get_battle_scores(starting_state::DynamicState, static_state::StaticState, N::Int64)
    return map(x -> play_battle(starting_state, static_state), 1:N)
end
