module SaunaDefaults
using SaunaModel:Stove, Room, SaunaNoWater, SaunaScenario, SteamThrowing
using Unitful:s, minute,°F, inch, cm, ft, Length, Area, Volume, W, m,Energy, kW, kJ, J, uconvert, ustrip, Power, K, °C, 
        Temperature, σ, Time, Frequency, hr, Pressure, Pa, atm, kg, lb, g, R, Mass, Quantity, mol, NoDims
const default_stove = let
    #http://saunawoodstove.com/
    exterior_surface_area_stove = 16inch*25inch*2 + 18inch*25inch*2 + 18inch*16inch*2
    stove_mass_estimate = uconvert(kg, 7.83g/cm^3*.25inch*(exterior_surface_area_stove ))
    rock_mass_estimate = uconvert(kg, 2.691*g/cm^3 *18inch*16inch*4inch)
    #https://www.engineeringtoolbox.com/specific-heat-capacity-d_391.html
    rock_specific_heat = 790J/(kg*K)
    stove_specific_heat = 490J/(kg*K)
    length_pipe= 1m
    radius_pipe = 3inch
    #https://www.engineeringtoolbox.com/overall-heat-transfer-coefficients-d_284.html
    convection_coeff_cast_iron = 7.9W/(m^2*K)
    #https://www.engineeringtoolbox.com/convective-heat-transfer-d_430.html
    surface_area_thrown_water = 1m^2
    convection_coeff_stove_water = 20W/(m^2*K)
    Stove(stove_mass_estimate, 
        rock_mass_estimate, 
        exterior_surface_area_stove, 
        length_pipe,
        radius_pipe,
        rock_specific_heat, 
        stove_specific_heat, 
        convection_coeff_cast_iron,
        surface_area_thrown_water,
        convection_coeff_stove_water
        )
end
const default_room = let
    height = 8ft
    width = 10ft
    depth = 6ft
    thickness_walls = .5inch
    mass_walls = 380kg/m^3*(width*depth+height*width*2 +height*depth*2)*thickness_walls
    furniture_mass = 100lb
    total_mass = mass_walls+furniture_mass
    thickness_insulation = 1inch 
    conduction_coeff_insulation = 0.04W/(m*K)
    convection_coeff = 7.9W/(m^2*K)
    specific_heat_cedar = 0.48kJ/(kg*K)
    Room(total_mass, 
    height, 
    width, 
    depth, 
    thickness_insulation, 
    conduction_coeff_insulation,
    convection_coeff,
    specific_heat_cedar)
end
function fire_temperature(time::Time,max_temperature::Temperature, start_temperature::Temperature )::Temperature
    start_temperature = uconvert(K,start_temperature)
    max_temperature = uconvert(K, max_temperature)
    uconvert(K,start_temperature+(1-exp(-time/20minute))*(max_temperature-start_temperature))
end
function fire_radius(time::Time, max_radius::Length, start_radius::Length )::Length
    start_radius = uconvert(m, start_radius)
    max_radius = uconvert(m, max_radius)
    uconvert(m,start_radius+(1-exp(-time/20minute))*(max_radius-start_radius))
end
const default_sauna = let
    sauna_room_view_factor = .6
    SaunaNoWater(default_stove,
                default_room,
                sauna_room_view_factor)
end
const default_scenario = let
    start_time = 0.0s
    end_time = 2.0hr
    start_temperature = 100.0°F
    max_temperature = 1000.0°F
    fire_temperature_curve(time) =  fire_temperature(time,max_temperature, start_temperature )
    start_radius = .04m
    max_radius = .3m
    fire_radius_curve(time) =  fire_radius(time, max_radius, start_radius)
    water_thrown_temperature = 40.0°F
    temperature_outside = 50.0°F
    scoop_size = 1.0lb
    pressure_outside = 1.0atm
    humidity_outside = 1212.0Pa*.3 #30% humidity
    temperature_floor = 50.0°F   
    initial_temperature = uconvert(K,51°F)
    water_throwing = SteamThrowing(150.0°F, water_thrown_temperature, scoop_size, (1.0/60)s^-1  )
    SaunaScenario(
        default_sauna,
        start_time,
        end_time,
        initial_temperature,
        initial_temperature,
        initial_temperature,
        fire_temperature_curve,
        fire_radius_curve,
        temperature_outside,
        humidity_outside,
        pressure_outside,
        temperature_floor,
        water_throwing
        )
end
end