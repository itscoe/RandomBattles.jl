using StaticArrays

struct ChargedAction
    move::Int8
    charge::Int8
end

const defaultCharge = ChargedAction(Int8(0), Int8(0))

struct SwitchAction
    pokemon::Int8
    time::Int8
end

const defaultSwitch = SwitchAction(Int8(0), Int8(0))

struct StaticState
    teams::SVector{2,StaticTeam}
end

struct DynamicState
    teams::SVector{2,DynamicTeam}
    fastMovesPending::SVector{2,Int8}
end

StaticState(teams::Array{Int64}; league = "great", cup = "open") =
    StaticState(Team(teams[1:(length(teams)÷2)]), Team(teams[(length(teams)÷2+1):length(teams)]))

StaticState(teams::Array{String}; league = "great", cup = "open") = StaticState(
    [StaticTeam(teams[1:3], league = league, cup = cup), StaticTeam(teams[4:6], league = league, cup = cup)]
)

DynamicState(state::StaticState) = DynamicState(
    DynamicTeam.(state.teams),
    [Int8(-1), Int8(-1)],
)
