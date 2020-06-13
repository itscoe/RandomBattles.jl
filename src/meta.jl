using JSON, HTTP, Distributions

struct Meta
    pokemon::Array{Pokemon}
    weights::Distribution
end

function Meta(cup::String; data_key = "all")
    resp = HTTP.get("https://silph.gg/api/cup/" * cup * "/stats/.json")
    data = JSON.parse(String(resp.body))
    silph_keys = collect(keys(data[data_key]))
    mons = silph_to_pvpoke.(silph_keys)
    meta_weights = map(x -> data[data_key][x]["percent"], silph_keys)
    return Meta(Pokemon.(silph_names), Categorical(meta_weights ./ sum(meta_weights)))
end
