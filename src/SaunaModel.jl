module SaunaModel

using DifferentialEquations 
using Unitful:s, Length, Area, Volume, W, m,Energy, kW, kJ, J, uconvert, ustrip, Power, K, °C, 
        Temperature, σ, Time, Frequency, hr, Pressure, Pa, kg, g, R, Mass, Quantity, mol
using JSON
 
include("types.jl")
include("heat_exchange.jl")
include("air_turnover.jl")
include("solve_sauna.jl")
include("api.jl")

volume(room::Room)::Volume = room.height*room.width*room.depth
outer_surface_area(room::Room)::Area = room.height*room.width*2 + room.height*room.depth*2 + room.height*room.width
floor_surface_area(room::Room)::Area = room.height*room.width
inner_surface_area(stove::Stove)::Area = stove.radius_pipe*2*π *stove.length_pipe

function pressure_bump_rate_boiled_water(boiled_water_mol_rate, temperature_air::Temperature, room::Room)
    uconvert(Pa/s,boiled_water_mol_rate * R * temperature_air/volume(room))
end
function unitize_variables(u::Vector)
    (u[1]K, u[2]K, u[3]K, u[4]Pa, u[5]kg, u[6]K)
end
function build_sauna_model(du, u, scenario, time)
    sauna = scenario.sauna
    temperature_stove, temperature_air, temperature_room , humidity_air, thrown_water_mass, temperature_thrown_water = unitize_variables(u)

    fire_stove_heat_exchange = radiance_exchange(scenario.fire_curve((time)s), temperature_stove, scenario.radius_fire((time)s)^2 *2 * π ) + 
                    convection_exchange(scenario.fire_curve((time)s), temperature_stove,inner_surface_area(sauna.stove), sauna.stove.convection_coeff)
    stove_room_heat_exchange = radiance_exchange(temperature_stove, temperature_room, sauna.stove.exterior_surface_area*sauna.sauna_room_view_factor)
    stove_air_heat_exchange = convection_exchange(temperature_stove, temperature_room, sauna.stove.exterior_surface_area, sauna.stove.convection_coeff )
    air_room_heat_exchange = convection_exchange(temperature_air, temperature_room, outer_surface_area(sauna.room), sauna.room.convection_coeff )
    air_floor_heat_exchange = convection_exchange(temperature_air, scenario.temperature_floor, floor_surface_area(sauna.room), sauna.room.convection_coeff )
    room_floor_heat_exchange = radiance_exchange(temperature_room, scenario.temperature_floor, .9*sauna.room.width*sauna.room.depth)
    air_turnover_portion = air_turnover(temperature_air - uconvert(K,scenario.temperature_outside), sauna.room)
    room_outside_conduction = conduction_exchange_wall(temperature_room, uconvert(K,scenario.temperature_outside), sauna.room)
    stove_water_heat = thrown_water_mass > 0.0kg ? convection_exchange(temperature_stove,temperature_thrown_water, sauna.stove.surface_area_thrown_water, sauna.stove.convection_coeff_water_stone ) : 0.0W
    heat_capacity_thrown_water = thrown_water_mass * specific_heat_water
    steam_heat_into_air = temperature_thrown_water>=100°C ? stove_water_heat : 0.0W
    boiled_water_mol_rate = uconvert(mol/s, steam_heat_into_air/enthalpy_vaporization_water)
    humidity_pressure_bump = pressure_bump_rate_boiled_water(boiled_water_mol_rate, temperature_air, sauna.room)
    du[1] = uconvert(K/s,(fire_stove_heat_exchange - stove_room_heat_exchange - stove_air_heat_exchange)/ heat_capacity(sauna.stove))|>ustrip 
    temperature_change_air_heat_exchange = (stove_air_heat_exchange - air_room_heat_exchange - air_floor_heat_exchange + steam_heat_into_air) / 
        heat_capacity_wet_air(sauna.room, scenario.atmospheric_pressure, humidity_air, temperature_air)
    temperature_change_air_mass_exchange = -(temperature_air -uconvert(K,scenario.temperature_outside) ) * air_turnover_portion
    du[2] = uconvert(K/s, temperature_change_air_heat_exchange + temperature_change_air_mass_exchange)|>ustrip
    du[3] = uconvert(K/s, (stove_room_heat_exchange + air_room_heat_exchange - room_outside_conduction -room_floor_heat_exchange) / heat_capacity(sauna.room))|>ustrip
    du[4] = uconvert(Pa/s, -(humidity_air-scenario.humidity_outside) * air_turnover_portion + humidity_pressure_bump)|>ustrip
    du[5] = uconvert(kg/s, -boiled_water_mol_rate*molar_mass_water)|>ustrip
    du[6] = uconvert(K/s, temperature_thrown_water<100°C && thrown_water_mass>0kg ? stove_water_heat/heat_capacity_thrown_water : 0K/s )|>ustrip
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

end # module
