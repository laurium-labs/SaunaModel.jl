include("default_components.jl")
include("results.jl")
using Unitful
function apply_json_mutations(object::Any, json::Dict)
    # This function recreates `object` with any mutations from `json`
     new_fields = map(fieldnames(typeof(object))) do field
        orig_field_value = getfield(object, field)
        if haskey(json, string(field))
            if orig_field_value isa Number
                return typeof(orig_field_value)(json[string(field)])
            else
                return apply_json_mutations(orig_field_value, json[string(field)])
            end
        else
            return orig_field_value
        end
    end
    return typeof(object)(new_fields...)
end

function get_json_description(object::Any)
    json = Dict()
    fields = fieldnames(typeof(object))
    for field in fields
        orig_field_value = getfield(object, field)
        if typeof(orig_field_value) <: Unitful.AbstractQuantity
            string_rep = string(orig_field_value)
            unit_string = string_rep[findfirst(isequal(' '), string_rep) + 1: end]
            json[string(field)] = Dict("val" => orig_field_value.val, "unit" => unit_string)
        else
            json[string(field)] = get_json_description(orig_field_value)
        end
    end
    return json
end

function dictionary_api(dictionary_sauna_specification::Dict)::Dict
    scenario = apply_json_mutations(SaunaDefaults.default_scenario, dictionary_sauna_specification)
    time, experinced_temperature, relative_humidity, human_heat_input = strip_units_results(extract_results(solve_sauna(scenario), scenario))
    result_dict = Dict("time" => time, "human_exper_temperature" => experinced_temperature, "relative_humidity" => relative_humidity, "watt_into_human" => human_heat_input)
end

function json_api(json_input::AbstractString)::String
    return JSON.json(dictionary_api(JSON.parse(json_input)))
end

function get_default_scenario_json()::String
    return JSON.json(get_json_description(SaunaDefaults.default_scenario))
end