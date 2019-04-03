include("default_components.jl")
include("results.jl")
function parse_scenario(config::Dict)::SaunaScenario
   sauna = haskey(config, "sauna") ?  parse_sauna(config["sauna"]) : SaunaDefaults.default_sauna
end 

function dictionary_api(dictionary_sauna_specification::Dict)::Dict
    scenario = haskey(dictionary_sauna_specification, "scenario") ? parse_scenario(dictionary_sauna_specification["scenario"]) : SaunaDefaults.default_scenario
    time, experinced_temperature, relative_humidity, real_feel = strip_units_results(extract_results(solve_sauna(scenario), scenario))
    result_dict = Dict("time" => time, "human_exper_temperature" => experinced_temperature, "relative_humidity" => relative_humidity, "real_feel" => real_feel)
end

function json_api(json_input::AbstractString)::String
    return JSON.json(dictionary_api(JSON.parse(json_input)))
end