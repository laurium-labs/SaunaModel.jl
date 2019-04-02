module SaunaModel

using DifferentialEquations 
using ParameterizedFunctions
using Unitful:s, Length, Area, W, m,Energy, kW, kJ, J, uconvert, ustrip, Power, K, °C, Temperature, σ, Time, hr, Pressure, Pa, kg, g, R, Mass, Quantity, mol
using JSON
 
abstract type AbstractSauna end
"""
fire_temperature is the average temperature of the fire
room_mass is the weight of wood and other sundries being heated with the sauna, and in direct thermal exchange
include("api.jl")

Diffusion of air:
https://www.nature.com/articles/7500229
A house was shown to have a turnover rate of .176 + .0162 ΔT
"""

struct Stove 
    mass::Mass
    rock_mass::Mass
    exterior_surface_area::Area
    length_pipe::Length
    radius_pipe::Length
    rock_specific_heat
    specific_heat
    convection_coeff
    surface_area_thrown_water::Area
    convection_coeff_water_stone
end
struct Room 
    mass::Mass
    height::Length
    width::Length
    depth::Length 
    thickness_insulation::Length 
    conduction_coeff
    convection_coeff
    specific_heat
end
struct SaunaNoWater <:AbstractSauna
    stove::Stove 
    room::Room
    fire_curve::Function
    temperature_outside::Temperature
    humidity_outside::Pressure
    atmospheric_pressure::Pressure
    temperature_floor::Temperature
    sauna_room_view_factor::Real
    water_thrown_temperature::Temperature
    scoop_size::Mass
end
const compared_house_surface_area = 50m^2 + 7m*8m*3 #approximation, three sides open, 50m^2 floors.
const compared_house_volume = 400m^3 #given
const specific_heat_water =  4.187kJ/(kg*K)
const enthalpy_vaporization_water = 40660J/mol
const molar_mass_water = 18.01527g/mol
function air_turnover(temperature_difference::Temperature, room::Room)
    room_surface_area_to_volume = outer_surface_area(room)/volume(room)
    sauna_term_factor = room_surface_area_to_volume/(compared_house_surface_area/compared_house_volume)
    #constants come from https://www.nature.com/articles/7500229
    sauna_term_factor*(.176*hr^-1 + .0162/(hr*K)*uconvert(K,temperature_difference))
end
volume(room::Room) = room.height*room.width*room.depth
outer_surface_area(room::Room) = room.height*room.width*2 + room.height*room.depth*2 + room.height*room.width
floor_surface_area(room::Room) = room.height*room.width

const air_conduction_coeff = 0.0262W/(m*K)
heat_capacity(room::Room) = room.mass * room.specific_heat
function heat_capacity(stove::Stove)
    stove.mass * stove.specific_heat + stove.rock_mass*stove.rock_specific_heat
end
function heat_capacity_wet_air(room::Room, atmospheric_pressure::Pressure, humidity_air::Pressure, temperature_air::Temperature) 
    dry_air_heat_capacity = 20.7643J/(mol*K)
    steam_heat_capacity = 28.03J/(mol*K)
    #ideal gas law
    mol_dry_air = uconvert(mol, volume(room) * (atmospheric_pressure- humidity_air)/(uconvert(K,temperature_air)*R))
    mol_steam = uconvert(mol, volume(room) * (humidity_air)/(uconvert(K,temperature_air)*R))
    dry_air_heat_capacity*mol_dry_air + steam_heat_capacity * mol_steam
end
function pressure_bump_rate_boiled_water(boiled_water_mol_rate, temperature_air::Temperature, room::Room)
    uconvert(Pa/s,boiled_water_mol_rate * R * temperature_air/volume(room))
end
function unitize_variables(u::Vector)
    (u[1]K, u[2]K, u[3]K, u[4]Pa, u[5]kg, u[6]K)
end
function build_sauna_model(du, u, sauna, time)
    temperature_stove, temperature_air, temperature_room , humidity_air, thrown_water_mass, temperature_thrown_water = unitize_variables(u)

    fire_stove_heat_exchange = fire_radiance_estimate(sauna.fire_curve((time)s), temperature_stove, .3m) + 
                                fire_convection_estimate(sauna.fire_curve((time)s), temperature_stove, sauna.stove)
    stove_room_heat_exchange = radiance_exchange(temperature_stove, temperature_room, sauna.stove.exterior_surface_area*sauna.sauna_room_view_factor)
    stove_air_heat_exchange = convection_exchange(temperature_stove, temperature_room, sauna.stove.exterior_surface_area, sauna.stove.convection_coeff )
    air_room_heat_exchange = convection_exchange(temperature_air, temperature_room, outer_surface_area(sauna.room), sauna.room.convection_coeff )
    air_floor_heat_exchange = convection_exchange(temperature_air, sauna.temperature_floor, floor_surface_area(sauna.room), sauna.room.convection_coeff )
    room_floor_heat_exchange = radiance_exchange(temperature_room, sauna.temperature_floor, .9*sauna.room.width*sauna.room.depth)
    air_turnover_portion = air_turnover(temperature_air - uconvert(K,sauna.temperature_outside), sauna.room)
    room_outside_conduction = conduction_exchange_wall(temperature_room, uconvert(K,sauna.temperature_outside), sauna.room)
    stove_water_heat = thrown_water_mass > 0.0kg ? convection_exchange(temperature_stove,temperature_thrown_water, sauna.stove.surface_area_thrown_water, sauna.stove.convection_coeff_water_stone ) : 0.0W
    heat_capacity_thrown_water = thrown_water_mass * specific_heat_water
    steam_heat_into_air = temperature_thrown_water>=100°C ? stove_water_heat : 0.0W
    boiled_water_mol_rate = uconvert(mol/s, steam_heat_into_air/enthalpy_vaporization_water)
    humidity_pressure_bump = pressure_bump_rate_boiled_water(boiled_water_mol_rate, temperature_air, sauna.room)
    du[1] = uconvert(K/s,(fire_stove_heat_exchange - stove_room_heat_exchange - stove_air_heat_exchange)/ heat_capacity(sauna.stove))|>ustrip 
    temperature_change_air_heat_exchange = (stove_air_heat_exchange - air_room_heat_exchange - air_floor_heat_exchange + steam_heat_into_air) / 
        heat_capacity_wet_air(sauna.room, sauna.atmospheric_pressure, sauna.humidity_outside, temperature_air)
    temperature_change_air_mass_exchange = -(temperature_air -uconvert(K,sauna.temperature_outside) ) * air_turnover_portion
    du[2] = uconvert(K/s, temperature_change_air_heat_exchange + temperature_change_air_mass_exchange)|>ustrip
    du[3] = uconvert(K/s, (stove_room_heat_exchange + air_room_heat_exchange - room_outside_conduction -room_floor_heat_exchange) / heat_capacity(sauna.room))|>ustrip
    du[4] = uconvert(Pa/s, -(humidity_air-sauna.humidity_outside) * air_turnover_portion + humidity_pressure_bump)|>ustrip
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
"""
Provides an estimate of the raidance power transmitted to a stove in a small fire.
"""
function fire_radiance_estimate(temperature_fire::Temperature, temperature_stove::Temperature, radius::Length)::Power
    radiance_exchange(temperature_fire, temperature_stove, radius^2 *2 * π )
end
function radiance_exchange(temperature_1::Temperature, temperature_2::Temperature, area::Area, emissivity=1)::Power
    emissivity * uconvert(W, σ * (uconvert(K,temperature_1) - uconvert(K, temperature_2))^4 * uconvert(m^2, area) )
end

function fire_convection_estimate(temperature_fire::Temperature, temperature_stove::Temperature, stove::Stove)::Power
    convection_exchange(temperature_fire, temperature_stove, stove.radius_pipe*2*π *stove.length_pipe, stove.convection_coeff)
end

function convection_exchange(temperature_1::Temperature, temperature_2::Temperature, area::Area, convective_coeff )::Power
    uconvert(W,convective_coeff*(uconvert(K,temperature_1)-uconvert(K,temperature_2)) * area)
end 
function conduction_exchange_wall(temperature_room::Temperature, temperature_outside::Temperature, room::Room)::Power
    uconvert(W, (uconvert(K,temperature_room) - uconvert(K, temperature_outside))*outer_surface_area(room)/room.thickness_insulation*room.conduction_coeff)
end
"""
integrator is from DifferentialEquations
"""
function throw_steam!(integrator)
    println("Steam thrown!")
    mass_thrown = uconvert(kg,integrator.p.scoop_size)|>ustrip
    new_mass_of_water = integrator.u[5] + mass_thrown
    integrator.u[6] = (integrator.u[6] * integrator.u[5] + ustrip(uconvert(K, integrator.p.water_thrown_temperature)) * mass_thrown)/new_mass_of_water
    integrator.u[5] = new_mass_of_water
    nothing
end
end # module
