function select_random_decision(d1::UInt8, d2::UInt8)
    r1, r2 = rand(0x01:Base.ctpop_int(d1)), rand(0x01:Base.ctpop_int(d2))
    to_return_1, to_return_2 = 0x08, 0x08
    for i = 0x00:0x06
        to_return_1 -= isodd(d1 >> i) && Base.ctpop_int(d1 >> i) == r1 ? 0x07 - i : 0x00
        to_return_2 -= isodd(d2 >> i) && Base.ctpop_int(d2 >> i) == r2 ? 0x07 - i : 0x00
    end
    return to_return_1, to_return_2
end

function get_possible_decisions(state::DynamicState, static_state::StaticState;
    allow_nothing::Bool = false, allow_overfarming::Bool = false)
    # 10000000 - shield
    # 01000000 - nothing
    # 00100000 - fast move
    # 00010000 - charged move
    # 00001000 - switch 1
    # 00000100 - switch 2
    # 00000010 - charged move 1
    # 00000001 - charged move 2

    d = 0x00, 0x00

    active = get_active(state)
    fast_moves_pending = get_fast_moves_pending(state)
    cmp = get_cmp(state)

    if isodd(cmp) # if team 1 is using a charged move and has cmp
        @inbounds d[2] = has_shield(state.teams[2]) ? 0x03 : 0x02
        @inbounds d[1] = get_energy(state.teams[1].mons[active[1]]) >=
            static_state.teams[1].mons[active[1]].chargedMoves[2] ?
            0xc0 : 0x40
    elseif !iszero(cmp) # if team 2 is using a charged move and has cmp
        @inbounds d[1] = has_shield(state.teams[1]) ? 0x03 : 0x02
        @inbounds d[2] = get_energy(state.teams[2].mons[active[2]]) >=
            static_state.teams[2].mons[active[2]].chargedMoves[2] ?
            0xc0 : 0x40
    else
        for i = 1:2
            if fast_moves_pending[i] <= 0x0001
                @inbounds if get_hp(state.teams[i].mons[active[i]]) != 0x0000 &&
                    (allow_overfarming ||
                    get_energy(state.teams[i].mons[active[i]]) != 0x0064)
                    @inbounds d[i] += 0x04
                end
                @inbounds if get_hp(state.teams[i].mons[active[i]]) != 0x0000 &&
                    get_energy(state.teams[i].mons[active[i]]) >=
                    static_state.teams[i].mons[active[i]].chargedMoves[1]
                    @inbounds d[i] += 0x08
                end
                @inbounds if get_hp(state.teams[i].mons[active[i] == 0x0001 ?
                    2 : 1]) != 0x0000
                    @inbounds d[i] += 0x10
                end
                @inbounds if get_hp(state.teams[i].mons[active[i] == 0x0003 ?
                    2 : 3]) != 0x0000
                    @inbounds d[i] += 0x20
                end
                if get_hp(state.teams[i].mons[active[i]]) != 0x0000 &&
                    allow_nothing
                    @inbounds d[i] += 0x02
                end
            else
                if get_hp(state.teams[i].mons[active[i]]) != 0x0000
                    @inbounds d[i] = 0x02
                else
                    @inbounds if get_hp(state.teams[i].mons[active[i] == 0x0001 ?
                        2 : 1]) != 0x0000
                        @inbounds d[i] += 0x10
                    end
                    @inbounds if get_hp(state.teams[i].mons[active[i] == 0x0003 ?
                        2 : 3]) != 0x0000
                        @inbounds d[i] += 0x20
                    end
                end
            end
        end
    end

    return d
end
