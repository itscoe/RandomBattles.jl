using StaticArrays

struct StaticIndividual
    mon::StaticIndividualPokemon
end

struct DynamicIndividual
    #These values are initialized, but change throughout the battle
    mon::DynamicPokemon
    buffs::StatBuffs         #Initially 0, 0
    shields::Int8            #Initially 2
end

StaticIndividual(mon::Union{Int64, String}; league::String = "great", cup::String = "open",
  opponent::Union{Nothing, StaticIndividualPokemon} = nothing) =
    StaticIndividual(StaticIndividualPokemon(mon, league = league, cup = cup, opponent = opponent))

DynamicIndividual(ind::StaticIndividual; shields::Int8 = Int8(2)) = DynamicIndividual(DynamicPokemon(ind.mon),
    defaultBuff, shields)
