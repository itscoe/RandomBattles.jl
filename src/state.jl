using StaticArrays

abstract type BattleState end

struct ChargedAction
    move::Move
    charge::Float64
end

const defaultCharge = ChargedAction(defaultMove, Float64(0.0))

struct SwitchAction
    pokemon::Int8
    time::Int16
end

const defaultSwitch = SwitchAction(Int8(0), Int16(0))

struct State <: BattleState
    teams::SVector{2,Team}
    agent::Int64
    fastMovesPending::SVector{2,Bool}
    chargedMovesPending::SVector{2,ChargedAction}
    switchesPending::SVector{2,SwitchAction}
end

function vectorize(state::State)
    return vcat(vectorize(state.teams[1]), vcat(vectorize(state.teams[2]),
        [1 == state.agent, 2 == state.agent]))
end

State(team1::Team, team2::Team) = State(
    [team1, team2],
    1,
    [false, false],
    [defaultCharge, defaultCharge],
    [defaultSwitch, defaultSwitch]
)

State(teams::Array{Int64}; league = "great", cup = "open") = State(
    [
     Team(
         Pokemon.(
            teams[1:(length(teams)÷2)],
            league = league,
            cup = cup,
         ),
         defaultBuff,
         0,
         Int8(2),
         1,
         rand(Bool),
     ),
     Team(
         Pokemon.(
             teams[(length(teams)÷2+1):length(teams)],
             league = league,
             cup = cup,
         ),
         defaultBuff,
         0,
         Int8(2),
         1,
         rand(Bool),
     ),
    ],
    1,
    [false, false],
    [defaultCharge, defaultCharge],
    [defaultSwitch, defaultSwitch]
)

State(teams::Array{String}; league = "great", cup = "open") = State(
    [Team(teams[1:3], league = league, cup = cup), Team(teams[4:6], league = league, cup = cup)],
    1,
    [false, false],
    [defaultCharge, defaultCharge],
    [defaultSwitch, defaultSwitch]
)
