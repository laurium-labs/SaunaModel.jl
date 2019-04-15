using Unitful:s,minute,°F, inch, ft,lb, g,kg,cm, Length, Area, W, J, kJ, m,Energy, kW, 
    uconvert, Power, K, Temperature, σ, Time, hr, Pressure, Pa, g, R, Mass, atm, ustrip
using SaunaModel:Room, Stove, SaunaNoWater, SaunaScenario, SteamThrowing, solve_sauna, SaunaDefaults
using SaunaModel:json_api
using SaunaModel:get_default_scenario_json

results = solve_sauna(SaunaDefaults.default_scenario)

json_api("{}")

get_default_scenario_json()