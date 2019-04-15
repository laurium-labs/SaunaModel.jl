include("default_components.jl")
include("results.jl")
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

function dictionary_api(dictionary_sauna_specification::Dict)::Dict
    scenario = apply_json_mutations(SaunaDefaults.default_scenario, dictionary_sauna_specification)
    extract_results(solve_sauna(scenario), scenario)
end

function json_api(json_input::AbstractString)::String
    return JSON.json(dictionary_api(JSON.parse(json_input)))
end