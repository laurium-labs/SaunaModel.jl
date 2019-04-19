function experienced_temperature(mean_air_temperature::Temperature,temperature_floor::Temperature )::Temperature 
    uconvert(K, temperature_floor)+(uconvert(K, mean_air_temperature)-uconvert(K, temperature_floor))*1.25
end
"""
`steam_throwing(u,p,t)` u, p, and t are inputs from the Differential Equations solver. u is the state, p is the solution 
paramenters, and t is the time. 
The steam throwing rate is determined by if the experinced temperature is higher than the cutoff to start taking steam. 
"""
function steam_throwing(u,p,t)
    experienced_temperature(u[2]K, p.temperature_floor)> p.steam_throwing.air_temperature_start_throwing ? uconvert(s^-1,p.steam_throwing.rate)|>ustrip : 0.0
end
"""
This function sets up the differential equation solvers, including the jump solver, runs the solver, then maps units back onto the results and returns a SaunaResults
"""
function solve_sauna(scenario::SaunaScenario )::SaunaResults
    stripped_stove_temperature = uconvert(K,scenario.initial_temperature_stove)|>ustrip
    stripped_air_temperature = uconvert(K, scenario.initial_temperature_air)|>ustrip
    stripped_room_temperature = uconvert(K,scenario.initial_temperature_room)|>ustrip
    stripped_humidity = uconvert(Pa, scenario.humidity_outside)|>ustrip
    u0 = [stripped_stove_temperature, stripped_air_temperature, stripped_room_temperature,stripped_humidity, ustrip(0kg), stripped_room_temperature  ]
    tspan = (uconvert(s,scenario.start_time)|>ustrip,uconvert(s,scenario.end_time)|>ustrip)
    p = scenario
    ode_prob = ODEProblem(build_sauna_model,u0,tspan,p)
    
    jump = VariableRateJump(steam_throwing,throw_steam!)
    jump_prob = JumpProblem(ode_prob,Direct(),jump)
    
    sol = solve(jump_prob,Tsit5())
    solved_times = map(time -> (time)s,sol.t)
    temperatures_stove = map(results -> (results[1])K, sol.u)
    temperatures_air = map(results -> (results[2])K, sol.u)
    temperatures_room = map(results -> (results[3])K, sol.u)
    pressures_humidity = map(results -> (results[4])Pa, sol.u)
    weights_thrown_water = map(results -> (results[5])kg, sol.u)
    temperatures_thrown_water = map(results -> (results[6])K, sol.u)
    SaunaResults(
        solved_times,
        temperatures_stove,
        temperatures_air,
        temperatures_room,
        pressures_humidity,
        weights_thrown_water,
        temperatures_thrown_water
    )
end
"""
`throw_steam!(integrator)` gets its argument integerator from DifferentialEquations
It updates the current mass of water that is on the stove, and adjusts the average temperature of water on the stove accordingly.
"""
function throw_steam!(integrator)
    mass_thrown = uconvert(kg,integrator.p.steam_throwing.scoop_size)|>ustrip
    new_mass_of_water = integrator.u[5] + mass_thrown
    integrator.u[6] = (integrator.u[6] * integrator.u[5] + ustrip(uconvert(K, integrator.p.steam_throwing.water_thrown_temperature)) * mass_thrown)/new_mass_of_water
    integrator.u[5] = new_mass_of_water
    nothing
end