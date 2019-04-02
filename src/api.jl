function json_api(json_input::AbstractString)::String 
    dictionary_input = JSON.parse(json_input)
end