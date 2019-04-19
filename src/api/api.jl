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
        elseif !(orig_field_value isa Function)
            json[string(field)] = get_json_description(orig_field_value)
        end
    end
    return json
end

function dictionary_api(dictionary_sauna_specification::Dict)::Dict
    scenario = apply_json_mutations(SaunaDefaults.default_scenario, dictionary_sauna_specification)
    extract_results(solve_sauna(scenario), scenario)
end
"""
Submit json description here, get json back. Temperatures are in Farenheit, humidity is in Pa, and power is in Watts.
"""
function json_api(json_input::AbstractString)::String
    return JSON.json(dictionary_api(JSON.parse(json_input)))
end
"""
Returns a default json configuration
"""
function get_default_scenario_json()::String
    return JSON.json(get_json_description(SaunaDefaults.default_scenario))
end