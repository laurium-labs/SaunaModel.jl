using Unitful:s,minute,°F, inch, ft,lb, g,kg,cm, Length, Area, W, J, kJ, m,Energy, kW, 
    uconvert, Power, K, Temperature, σ, Time, hr, Pressure, Pa, g, R, Mass, atm, ustrip
using SaunaModel:Room, Stove, SaunaNoWater, SaunaScenario, SteamThrowing, solve_sauna, SaunaDefaults

results = solve_sauna(SaunaDefaults.default_scenario)
