module Main
import JSON

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    j = JSON.parse(ARGS[1])
    time = [1,2,3,4]
    temperature = [j["room_volume"] * .25, j["room_volume"]* .25, j["room_volume"]* .25, j["room_volume"]* .25]
    humidity = [j["stove_volume"] * .75, j["stove_volume"]* .75, j["stove_volume"]* .75, j["stove_volume"]* .75]
    result = Dict("time" => time, "temperature" => temperature, "humidity" => humidity)
    println(JSON.json(result))
    return 0
end

end