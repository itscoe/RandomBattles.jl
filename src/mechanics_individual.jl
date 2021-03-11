function get_cmp(state::DynamicIndividualState, static_state::StaticIndividualState, dec::Decision)
    @inbounds dec.chargedMovesPending[1].charge + dec.chargedMovesPending[2].charge == Int8(0) && return Int8(0), Int8(0)
    @inbounds dec.chargedMovesPending[2].charge == Int8(0) && return Int8(1), Int8(0)
    @inbounds dec.chargedMovesPending[1].charge == Int8(0) && return Int8(2), Int8(0)
    @inbounds static_state.teams[1].mon.stats.attack > static_state.teams[2].mon.stats.attack && return Int8(1), Int8(2)
    @inbounds static_state.teams[1].mon.stats.attack < static_state.teams[2].mon.stats.attack && return Int8(2), Int8(1)
    cmp = rand((Int8(1), Int8(2)))
    return cmp, (cmp == Int8(1) ? Int8(2) : Int8(1))
end

function evaluate_fast_moves(state::DynamicIndividualState, static_state::StaticIndividualState, agent::Int8)
    if agent == Int8(1)
        @inbounds return DynamicIndividualState(@SVector[DynamicIndividual(
            DynamicPokemon(state.teams[1].mon.hp,
            min(state.teams[1].mon.energy + static_state.teams[1].mon.fastMove.energy,
            Int8(100))), state.teams[1].buffs, state.teams[1].shields),
            DynamicIndividual(DynamicPokemon(max(
                Int16(0),
                state.teams[2].mon.hp -
                calculate_damage(
                    static_state.teams[1].mon,
                    get_atk(state.teams[1].buffs),
                    static_state.teams[2].mon,
                    get_def(state.teams[2].buffs),
                    static_state.teams[1].mon.fastMove,
                    Int8(100),
                ),
            ), state.teams[2].mon.energy), state.teams[2].buffs,
            state.teams[2].shields)], state.fastMovesPending)
    else
        @inbounds return DynamicIndividualState(@SVector[
            DynamicIndividual(DynamicPokemon(max(
                Int16(0),
                state.teams[1].mon.hp -
                calculate_damage(
                    static_state.teams[2].mon,
                    get_atk(state.teams[2].buffs),
                    static_state.teams[1].mon,
                    get_def(state.teams[1].buffs),
                    static_state.teams[2].mon.fastMove,
                    Int8(100),
                ),
            ), state.teams[1].mon.energy), state.teams[1].buffs,
            state.teams[1].shields), DynamicIndividual(
            DynamicPokemon(state.teams[2].mon.hp,
            min(state.teams[2].mon.energy + static_state.teams[2].mon.fastMove.energy,
            Int8(100))), state.teams[2].buffs, state.teams[2].shields)], state.fastMovesPending)
    end
end

function evaluate_charged_moves(state::DynamicState, static_state::StaticState, cmp::Int8, move_id::Int8, charge::Int8, shielding::Bool, buffs_applied::Bool)
    if cmp == Int8(1)
        @inbounds return DynamicIndividualState(@SVector[
            DynamicIndividual(DynamicPokemon(state.teams[1].mon.hp,
                min(state.teams[1].mon.energy - static_state.teams[1].mon.chargedMoves[move_id].energy, Int8(0))),
            buffs_applied ? state.teams[1].buffs + static_state.teams[1].mon.chargedMoves[move_id].self_buffs : state.teams[1].buffs,
            state.teams[1].shields),
            DynamicIndividual(shielding ? state.teams[2].mon : DynamicPokemon(max(
                Int16(0),
                state.teams[2].mon.hp -
                calculate_damage(
                    static_state.teams[1].mon,
                    get_atk(state.teams[1].buffs),
                    static_state.teams[2].mon,
                    get_def(state.teams[2].buffs),
                    static_state.teams[1].mon.chargedMoves[move_id],
                    Int8(100),
                ),
            ), state.teams[2].mon.energy),
            buffs_applied ? (state.teams[2].buffs + static_state.teams[1].mon.chargedMoves[move_id].opp_buffs) : state.teams[2].buffs,
            shielding ? state.teams[2].shields - Int8(1) : state.teams[2].shields)], state.fastMovesPending)
    else
        @inbounds return DynamicIndividualState(@SVector[
            DynamicIndividual(shielding ? state.teams[1].mon : DynamicPokemon(max(
                Int16(0),
                state.teams[1].mon.hp -
                calculate_damage(
                    static_state.teams[2].mon,
                    get_atk(state.teams[2].buffs),
                    static_state.teams[1].mon,
                    get_def(state.teams[1].buffs),
                    static_state.teams[2].mon.chargedMoves[move_id],
                    Int8(100),
                ),
            ), state.teams[1].mon.energy),
            buffs_applied ? (state.teams[1].buffs + static_state.teams[2].mon.chargedMoves[move_id].opp_buffs) : state.teams[1].buffs,
            shielding ? state.teams[1].shields - Int8(1) : state.teams[1].shields),
            DynamicIndividual(DynamicPokemon(state.teams[2].mon.hp,
                min(state.teams[2].mon.energy - static_state.teams[2].mon.chargedMoves[move_id].energy, Int8(0))),
            buffs_applied ? state.teams[2].buffs + static_state.teams[2].mon.chargedMoves[move_id].self_buffs : state.teams[2].buffs,
            state.teams[2].shields)], state.fastMovesPending)
    end
end

function step_timers(state::DynamicIndividualState, fmCooldown1::Int8, fmCooldown2::Int8)
    @inbounds return DynamicIndividualState(
        state.teams,
        @SVector[fmCooldown1 == Int8(0) ? max(Int8(-1), state.fastMovesPending[1] - Int8(1)) : fmCooldown1 - Int8(1),
            fmCooldown2 == Int8(0) ? max(Int8(-1), state.fastMovesPending[2] - Int8(1)) : fmCooldown2 - Int8(1)])
end
