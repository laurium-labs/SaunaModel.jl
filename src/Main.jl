module Main
using SaunaModel:json_api
Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    println(json_api(ARGS[1]))
    return 0
end

end