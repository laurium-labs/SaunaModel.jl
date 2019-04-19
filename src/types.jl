abstract type AbstractSauna end

"""
A stove can be described by its dimensions and specific heats. The stove is assumed to be made out of steel.
"""
struct Stove 
    width::Length
    depth::Length
    height::Length
    thickness_stove_wall::Length
    length_pipe::Length
    radius_pipe::Length
    rock_specific_heat
    specific_heat
    convection_coeff
    surface_area_thrown_water::Area
    convection_coeff_water_stone
end
"""
A room is described by its dimensions, heat transfer coefficients, and specific heat. A density is assumed to compute room mass.
"""
struct Room 
    height::Length
    width::Length
    depth::Length 
    thickness_wall::Length
    thickness_insulation::Length 
    conduction_coeff
    convection_coeff
    specific_heat
end
"""
A sauna consists of a stove and room description, as well as a view factor of the room itself from the sauna, which is an estimate of how much of the stoves area is exposed to the room.
"""
struct SaunaNoWater <:AbstractSauna
    stove::Stove 
    room::Room
    sauna_room_view_factor::Real
end
"""
Steam throwing describes how steam is thrown in a sauna. A temperature to start throwing steam must be selected in order to know when someone would enter the sauna.
"""
struct SteamThrowing
    air_temperature_start_throwing::Temperature
    water_thrown_temperature::Temperature
    scoop_size::Mass
    rate::Frequency
end
"""
The fire is the driving heat source of the sauna system. A sigmoid heating function is used to drive the fire temperature up over about a 20 minute period
"""
struct Fire 
    initial_temperature::Temperature
    final_temperature::Temperature
    initial_radius::Length
    final_radius::Length
end 
"""
The sauna scenario brings many of the components together, as well as initial and boudnary conditions.
"""
struct SaunaScenario
    sauna::SaunaNoWater
    start_time::Time 
    end_time::Time 
    initial_temperature_stove::Temperature
    initial_temperature_air::Temperature
    initial_temperature_room::Temperature
    fire::Fire
    temperature_outside::Temperature
    humidity_outside::Pressure
    atmospheric_pressure::Pressure
    temperature_floor::Temperature
    steam_throwing::SteamThrowing
end
"""
Sauna results store the state of the system at each time step. Temperatures of the stove, air, room, and water on stove are tracked as well as room humidity and mass of water on stove.
"""
struct SaunaResults
    times::Vector{<:Time}
    temperatures_stove::Vector{<:Temperature}
    temperatures_air::Vector{<:Temperature}
    temperatures_room::Vector{<:Temperature}
    pressures_humidity::Vector{<:Pressure}
    weights_thrown_water::Vector{<:Mass}
    temperatures_thrown_water::Vector{<:Temperature}
end


const specific_heat_water =  4.187kJ/(kg*K)
const enthalpy_vaporization_water = 40660J/mol
const molar_mass_water = 18.01527g/mol
const air_conduction_coeff = 0.0262W/(m*K)
