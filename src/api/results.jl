"""
Empirical estimate of vapor pressure: https://en.wikipedia.org/wiki/Vapour_pressure_of_water
"""
function august_roche_magnus_vapor_pressure(temperature::Temperature)::Pressure 
    celsius_temperature = uconvert(°C, temperature )|>ustrip
    (610.94*exp(17.625 * celsius_temperature/(celsius_temperature + 243.04)))Pa
end
"""
This function attempts to estimate how much your ears and neck will burn from the onslaught of steam
    The government has a estimate that doesn't work. 
    https://www.weather.gov/media/oun/wxsafety/summerwx/heatindex.pdf
"""
function apparent_temperature(temperature::Temperature, relative_humidity_ratio::Real)::Temperature
    relative_humidity = 100 * relative_humidity_ratio
    farenheit_temp = uconvert(°F, temperature)|>ustrip
    return (-42.379 + 2.049015*farenheit_temp + 10.1433*relative_humidity -.2247*farenheit_temp*relative_humidity - 6.83*10^-3*farenheit_temp^2
    - 5.48*10^-2*relative_humidity^2 + 1.2287*10^-3*farenheit_temp^2*relative_humidity + 8.528*10^-4*farenheit_temp*relative_humidity^2 -1.99*10^-6*farenheit_temp^2*relative_humidity^2 )°F
end
function extract_results(solution::SaunaResults, scenario::SaunaScenario)
    human_exper_temperatures= map(temperature_air -> experienced_temperature(temperature_air, scenario.temperature_floor), solution.temperatures_air)
    ratio_steam_atmosphere = map( solution.pressures_humidity) do pressure_humidity
        uconvert(Pa, pressure_humidity)/(uconvert(Pa, scenario.atmospheric_pressure))
    end
    human_heat_input = _heat_into_humans(solution, scenario)
    return (solution.times, human_exper_temperatures, ratio_steam_atmosphere, human_heat_input )
end

function strip_units_results(results)
    time, human_exper_temperatures, ratio_steam_atmosphere, human_heat_input = results
    stripped_times = map(time -> uconvert(s,time)|>ustrip, time)
    stripped_human_exper_temperatures = map(temperature -> uconvert(°F, temperature)|>ustrip, human_exper_temperatures)
    stripped_human_heat_input = map(power -> uconvert(W, power)|>ustrip, human_heat_input)
    return (stripped_times, stripped_human_exper_temperatures, ratio_steam_atmosphere, stripped_human_heat_input)
end