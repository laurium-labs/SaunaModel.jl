module SaunaModel

using DifferentialEquations 
using Unitful:s, minute,°F, °C, inch, Length, Area, Volume, W, cm, m,Energy, kW, kJ, J, uconvert, ustrip, Power, K, °C, 
        Temperature, σ, Time, Frequency, hr, Pressure,kPa, Pa, atm, kg, g, lb, R, Mass, Quantity, mol, N, DimensionlessQuantity
using JSON
using Interpolations
 
include("types.jl")
include("heat_exchange.jl")
include("air_turnover.jl")
include("solve_sauna.jl")
include("api/api.jl")

volume(room::Room)::Volume = room.height*room.width*room.depth
outer_surface_area(room::Room)::Area = room.height*room.width*2 + room.height*room.depth*2 + room.height*room.width
outer_surface_area(stove::Stove)::Area = 2*(stove.width*stove.height + stove.width*stove.depth + stove.depth*stove.height)
floor_surface_area(room::Room)::Area = room.height*room.width
inner_surface_area(stove::Stove)::Area = stove.radius_pipe*2*π *stove.length_pipe

function pressure_bump_rate_boiled_water(boiled_water_mol_rate, temperature_air::Temperature, room::Room)
    uconvert(Pa/s,boiled_water_mol_rate * R * temperature_air/volume(room))
end
function unitize_variables(u::Vector)
    (u[1]K, u[2]K, u[3]K, u[4]Pa, u[5]kg, u[6]K)
end
function fire_temperature(fire::Fire, time::Time)::Temperature
    start_temperature = uconvert(K,fire.initial_temperature)
    max_temperature = uconvert(K, fire.final_temperature)
    uconvert(K,start_temperature+(1-exp(-uconvert(s/s,time/20minute)|>ustrip))*(max_temperature-start_temperature))
end
function fire_radius(fire::Fire, time::Time )::Length
    start_radius = uconvert(m, fire.initial_radius)
    max_radius = uconvert(m, fire.final_radius)
    uconvert(m,start_radius+(1-exp(-time/20minute))*(max_radius-start_radius))
end
"""
`build_sauna_model(du, u, scenario, raw_time)` describes how the system evolves smoothly through time (not including steam throwing)
This is fed to the ODESolver of Differential Equations. The first argument is the derivative, and must be updated to match how the system is evolving.
There are many interactions, driven by radiance, convection, conduction, advection, and phase change.
"""
function build_sauna_model(du, u, scenario, raw_time)
    sauna = scenario.sauna
    time = (raw_time)s
    temperature_stove, temperature_air, temperature_room , humidity_air, thrown_water_mass, temperature_thrown_water = unitize_variables(u)

    fire_stove_heat_exchange = radiance_exchange(fire_temperature(scenario.fire, time), temperature_stove, fire_radius(scenario.fire, time)^2 *2 * π ) + 
                    convection_exchange(fire_temperature(scenario.fire, time), temperature_stove,inner_surface_area(sauna.stove), sauna.stove.convection_coeff)
    stove_room_heat_exchange = radiance_exchange(temperature_stove, temperature_room, outer_surface_area(sauna.stove)*sauna.sauna_room_view_factor)
    stove_air_heat_exchange = convection_exchange(temperature_stove, temperature_room, outer_surface_area(sauna.stove), sauna.stove.convection_coeff )
    air_room_heat_exchange = convection_exchange(temperature_air, temperature_room, outer_surface_area(sauna.room), sauna.room.convection_coeff )
    air_floor_heat_exchange = convection_exchange(temperature_air, scenario.temperature_floor, floor_surface_area(sauna.room), sauna.room.convection_coeff )
    room_floor_heat_exchange = radiance_exchange(temperature_room, scenario.temperature_floor, .9*sauna.room.width*sauna.room.depth)
    air_turnover_portion = air_turnover(temperature_air - uconvert(K,scenario.temperature_outside), sauna.room)
    room_outside_conduction = conduction_exchange_wall(temperature_room, uconvert(K,scenario.temperature_outside), sauna.room)
    stove_water_heat = thrown_water_mass > 0.0kg ? convection_exchange(temperature_stove,temperature_thrown_water, sauna.stove.surface_area_thrown_water, sauna.stove.convection_coeff_water_stone ) : 0.0W
    heat_capacity_thrown_water = thrown_water_mass * specific_heat_water
    heat_into_water = temperature_thrown_water >= 100°C ? stove_water_heat : 0.0W
    boiled_water_mol_rate = uconvert(mol/s, heat_into_water/enthalpy_vaporization_water)
    steam_heat_into_air = (100°C - temperature_air ) * boiled_water_mol_rate * steam_heat_capacity
    humidity_pressure_bump = pressure_bump_rate_boiled_water(boiled_water_mol_rate, temperature_air, sauna.room)
    du[1] = uconvert(K/s,(fire_stove_heat_exchange - stove_room_heat_exchange - stove_air_heat_exchange)/ heat_capacity(sauna.stove))|>ustrip 
    temperature_change_air_heat_exchange = uconvert(K/s,(stove_air_heat_exchange - air_room_heat_exchange - air_floor_heat_exchange + steam_heat_into_air) / 
        heat_capacity_wet_air(sauna.room, scenario.atmospheric_pressure, humidity_air, temperature_air))
    heat_capacity_ratio = heat_capacity_wet_air(sauna.room, scenario.atmospheric_pressure, scenario.humidity_outside, temperature_air)/heat_capacity_wet_air(sauna.room, scenario.atmospheric_pressure, humidity_air, temperature_air)
    temperature_change_air_mass_exchange = uconvert(K/s,-(temperature_air -uconvert(K,scenario.temperature_outside) ) * air_turnover_portion * heat_capacity_ratio)
    du[2] = uconvert(K/s, temperature_change_air_heat_exchange + temperature_change_air_mass_exchange)|>ustrip
    du[3] = uconvert(K/s, (stove_room_heat_exchange + air_room_heat_exchange - room_outside_conduction -room_floor_heat_exchange) / heat_capacity(sauna.room))|>ustrip
    du[4] = uconvert(Pa/s, -(humidity_air-scenario.humidity_outside) * air_turnover_portion + humidity_pressure_bump)|>ustrip
    du[5] = uconvert(kg/s, -boiled_water_mol_rate*molar_mass_water)|>ustrip
    du[6] = uconvert(K/s, temperature_thrown_water<100.1°C && thrown_water_mass>0kg ? stove_water_heat/heat_capacity_thrown_water : 0K/s )|>ustrip
    nothing
end

# 4 logs of foot and a half, 4 inch triangle
surface_area_triangle_log(length::Length, thickness::Length)::Area = length*thickness*3 + thickness^2
""" 
Availible energy
https://ncfs.ucf.edu/burn_db/Thermal_Properties/docs/Kim_HRR_of_Burning_Items_in_Fires.pdf
125 kW per m^2 of board

Efficency of stove
https://www.chimneysweeponline.com/wscompe.htm
We will believe them that they are twice as efficent as a sauna stove
"""
fire_steady_state(surface_area_board::Area)::Power = 125000W/m^2 * uconvert(m^2,surface_area_board)*.4

export Stove, Room, SaunaNoWater, SteamThrowing, Fire, SaunaScenario, 
SaunaResults, solve_sauna, dictionary_api, get_default_scenario_json, 
build_sauna_model, throw_steam!,steam_throwing,
compute_effective_convection_coeff,surface_moisture_resistance, 
evaporation_cooling, skin_moisture_resistance, heat_into_humans,
conduction_exchange_wall, convection_exchange, radiance_exchange, air_turnover
end # module
