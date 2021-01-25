using StaticArrays

struct Individual
    #These values are initialized, but change throughout the battle
    mons::SVector{1,Pokemon}
    buffs::StatBuffs         #Initially 0, 0
    switchCooldown::Int8     #Initially 0
    shields::Int8            #Initially 2
    active::Int8             #Initially 1 (the lead)
    shielding::Bool          #Initially random
end

function vectorize(ind::Individual)
    return vcat(vectorize(ind.mons[1]), [ind.buffs.atk, ind.buffs.def, ind.switchCooldown, ind.shields])
end

Individual(
    mons::Array{Int64};
    league::String = "great",
    cup::String = "open",
    shields = 2,
) = Individual(Pokemon.(mons, league = league, cup = cup), defaultBuff, Int8(0), shields, Int8(1), rand(Bool))

Individual(mons::Array{String}; league::String = "great", cup::String = "open", shields = 2) =
    Individual(Pokemon.(mons, league = league, cup = cup), defaultBuff, Int8(0), shields, Int8(1), rand(Bool))

Individual(mons::Array{Pokemon}, shields = 2) =
    Individual(mons, defaultBuff, Int8(0), shields, Int8(1), rand(Bool))

function Setfield.:setindex(arr::StaticArrays.SVector{2, Individual}, t::Individual, i::Int8)
    return setindex(arr, t, Int64(i))
end
