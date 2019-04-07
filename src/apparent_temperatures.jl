const body_surface_area = 1.78m^2
const body_convective_coeff = 12.3W/(m^2*K)
const body_water_pressure = 5.65kPa
const view_factor_external_body_naked = .8
const significant_diameter = 15.3cm
const body_temperature = 37°C
const view_factor_stove = .1
const sweating_efficency = .6
function skin_moisture_resistance(temperature_air::Temperature)
    if temperature_air < 30°C
        return .032m^2*kPa/W
    elseif temperature_air < 40°C
        return .0125m^2*kPa/W
    elseif temperature_air < 50°C
        return .0062m^2*kPa/W
    else
        return .0037m^2*kPa/W
    end
end
function surface_moisture_resistance(pressure_humidity::Pressure)
    ((199+ 1.6*ustrip(uconvert(kPa,pressure_humidity)))^-1)m^2*kPa/W
end
function evaporation_cooling(temperature_air::Temperature, pressure_humidity::Pressure)::Power
    skin_resistance = skin_moisture_resistance(temperature_air)
    surface_resistance = surface_moisture_resistance(pressure_humidity)
    uconvert(W,(body_water_pressure-pressure_humidity)*sweating_efficency*body_surface_area/(skin_resistance+surface_resistance))
end
function _heat_into_humans(temperature_air::Temperature, temperature_room::Temperature, pressure_humidity::Pressure, temperature_stove::Temperature, scenario::SaunaScenario)::Power
    stove_vf = scenario.sauna.stove.exterior_surface_area/4/outer_surface_area(scenario.sauna.room)
    radiation_with_room = radiance_exchange(temperature_air, body_temperature, body_surface_area*(1-stove_vf)*view_factor_external_body_naked)
    radiation_with_stove = radiance_exchange(temperature_stove, body_temperature, body_surface_area*stove_vf*view_factor_external_body_naked)
    convection_with_room = convection_exchange(temperature_air, body_temperature, body_surface_area, body_convective_coeff )
    evap_cooling = evaporation_cooling(temperature_air, pressure_humidity)
    return radiation_with_room+radiation_with_stove+convection_with_room-evap_cooling
end

function _heat_into_humans(results::SaunaResults, scenario::SaunaScenario)
    map(results.temperatures_air, results.temperatures_room, results.pressures_humidity, results.temperatures_stove) do temperature_air, temperature_room, pressure_humidity, temperature_stove
        _heat_into_humans(temperature_air, temperature_room, pressure_humidity, temperature_stove,scenario)
    end
end