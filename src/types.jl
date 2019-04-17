abstract type AbstractSauna end

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
fire_temperature is the average temperature of the fire
room_mass is the weight of wood and other sundries being heated with the sauna, and in direct thermal exchange
https://www.engineersedge.com/heat_transfer/convective_heat_transfer_coefficients__13378.htm

"""
struct SaunaNoWater <:AbstractSauna
    stove::Stove 
    room::Room
    sauna_room_view_factor::Real
end
struct SteamThrowing
    air_temperature_start_throwing::Temperature
    water_thrown_temperature::Temperature
    scoop_size::Mass
    rate::Frequency
end
struct Fire 
    initial_temperature::Temperature
    final_temperature::Temperature
    initial_radius::Length
    final_radius::Length
end 
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
