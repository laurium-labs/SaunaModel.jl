using DifferentialEquations 
using ParameterizedFunctions
using Unitful:s,minute,°F, inch, ft,lb, g,kg,cm, Length, Area, W, J, kJ, m,Energy, kW, uconvert, Power, K, Temperature, σ, Time, hr, Pressure, Pa, g, R, Mass, atm, ustrip
using SaunaModel:Room, Stove, SaunaNoWater,build_sauna_model, throw_steam!
example_stove = let
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
example_room = let
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
function fire_temperature(time::Time,max_temperature::Temperature, start_temperature::Temperature )
    start_temperature = uconvert(K,start_temperature)
    max_temperature = uconvert(K, max_temperature)
    uconvert(K,start_temperature+(1-exp(-time/20minute))*(max_temperature-start_temperature))
end
sauna = let
    start_temperature = 100°F
    max_temperature = 2500°F
    fire_curve(time) =  fire_temperature(time,max_temperature, start_temperature )
    humidity_outside = 1212Pa*.3 #30% humidity
    pressure_outside = 1atm
    temperature_floor = 50°F   
    sauna_room_view_factor = .6
    water_thrown_temperature = 40°F
    scoop_size = 1lb
    SaunaNoWater(example_stove,
                example_room,
                fire_curve,
                temperature_floor,
                humidity_outside,
                pressure_outside,
                temperature_floor,
                sauna_room_view_factor,
                water_thrown_temperature,
                scoop_size)
end
# build_sauna_model([0.0K/s,0.0K/s,0.0K/s,0.0Pa/s],  sauna::SaunaNoWater, 0s)
initial_temperature = ustrip(uconvert(K,51°F))
u0 = [initial_temperature,initial_temperature,initial_temperature,ustrip(1212Pa*.3), ustrip(0kg), initial_temperature  ]
tspan = (ustrip(0.0s),uconvert(s,1.0hr)|>ustrip)
p = sauna
ode_prob = ODEProblem(build_sauna_model,u0,tspan,p)
steam_thrown_rate(u,p,t) = u[2]>uconvert(K,30°F)|>ustrip ? 1/120.0 : 0.0

jump = ConstantRateJump(steam_thrown_rate,throw_steam!)
jump_prob = JumpProblem(ode_prob,Direct(),jump)

sol = solve(jump_prob,Tsit5())
