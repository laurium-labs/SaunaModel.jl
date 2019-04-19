const body_surface_area = 1.78m^2
const body_mass = 150lb
const body_specific_heat = 3470J/(kg*K)
const body_core_temperature = 98.6°F
const body_convective_coeff = 12.3W/(m^2*K)
const body_water_pressure = 5.65kPa
const view_factor_external_body_naked = .8
const significant_diameter = 15.3cm
const body_temperature = 37°C
const view_factor_stove = .1
const sweating_efficency = .6
const skin_moisture_resistance_itp = let
    temperatures = [30°C,40°C,50°C, 55°C ]
    results = [.032m^2*kPa/W, .0125m^2*kPa/W, .0062m^2*kPa/W, .0037m^2*kPa/W]
    itp = interpolate((temperatures,), results, Gridded(Linear()))
    extrapolate(itp, Flat())
end
const kinematic_viscosity_itp = let 
    temperatures=[20°F, 70°F, 120°F, 140°F, 160°F, 200°F]
    results = [(16.82*10^-6)m^2/s, (18.18*10^-6)m^2/s, (19.48*10^-6)m^2/s, (19.99*10^-6)m^2/s,(20.49*10^-6)m^2/s, (21.46*10^-6)m^2/s]
    itp = interpolate((temperatures,), results, Gridded(Linear()))
    extrapolate(itp, Line())
end 
const dynamic_viscosity_itp = let 
    temperatures=[20°F, 70°F, 120°F, 140°F, 160°F, 200°F]
    results = [(12.71*10^-6)N*s/m^2, (15.61*10^-6)N*s/m^2, (17.78*10^-6)N*s/m^2, (18.86*10^-6)N*s/m^2,(19.97*10^-6)N*s/m^2, (22.27*10^-6)N*s/m^2]
    itp = interpolate((temperatures,), results, Gridded(Linear()))
    extrapolate(itp, Line())
end 
const air_speed_guess_itp = let
    speeds = cat(dims=1, [.3m/s], map(idx -> (idx)m/s, 1:6))
    pressure_Δ  = [0Pa/s, .6Pa/s, 2.4Pa/s, 5.4Pa/s, 9.6Pa/s, 15Pa/s, 22Pa/s]
    itp = interpolate((pressure_Δ,), speeds, Gridded(Linear()))
    extrapolate(itp, Line())
end
const air_thermal_conductivity_itp = let
    temperatures=[25°C, 125°C]
    results = [(0.0262)W/(m*K), (0.0333)W/(m*K)]
    itp = interpolate((temperatures,), results, Gridded(Linear()))
    extrapolate(itp, Line())
end 
"""
`skin_moisture_resistance(pressure_humidity::Pressure)` takes the air temperature as an argument and returns surface moisture resistance.
Data is drawn from:
The Assessment of Sultriness. Part I: A Temperature-Humidity Index Based on Human Physiology and Clothing Science -Steadman
Table 3
"""
function skin_moisture_resistance(temperature_air::Temperature)
    skin_moisture_resistance_itp(uconvert(°C, temperature_air  ))
end
"""
`surface_moisture_resistance(pressure_humidity::Pressure)` takes a the humidity as an argument and returns surface moisture resistance.
Data is drawn from:
The Assessment of Sultriness. Part I: A Temperature-Humidity Index Based on Human Physiology and Clothing Science -Steadman
Table 3
"""
function surface_moisture_resistance(pressure_humidity::Pressure)
    ((199+ 1.6*ustrip(uconvert(kPa,pressure_humidity)))^-1)m^2*kPa/W
end
"""
Evaporative cooling depends on skin and surface resistance to pressure. Skin resistance to pressure drops as temperature rises.
"""
function evaporation_cooling(temperature_air::Temperature, pressure_humidity::Pressure)::Power
    skin_resistance = skin_moisture_resistance(temperature_air)
    surface_resistance = surface_moisture_resistance(pressure_humidity)
    uconvert(W,(body_water_pressure-pressure_humidity)*sweating_efficency*body_surface_area/(skin_resistance+surface_resistance))
end
function Nu_cylinder(Re::DimensionlessQuantity, Pr::DimensionlessQuantity)::DimensionlessQuantity
    if .4 < Re<4
        return 0.989*Re^0.33*Pr^.3333
    elseif Re < 40
        return 0.911*Re^0.385*Pr^.3333
    elseif Re < 4000
        return .683*Re^.466*Pr^.3333
    elseif Re < 40000
        return .193*Re^.618*Pr^.3333
    elseif Re < 400000
        return .027*Re^.805*Pr^.3333
    end 
end
"""
`compute_effective_convection_coeff` estimates a convection coefficent based on the change in humidity, air temperature, humidity, and the overall scenario
This involves estimating an air speed (based on change in humidity), kinematic viscosity, dynamic viscosity, air thermal conductivity, and air specific heat.
These are used in turn to estimate a Reynolds number and a Prantl number, which is used with the cylindrical estimate of a Nussult number.
The Nussult number is used to estimate a convection coefficient.
"""
function compute_effective_convection_coeff(pressure_Δ, temperature_air::Temperature, humidity_air::Pressure, atmospheric_pressure::Pressure)
    speed = air_speed_guess_itp(abs(pressure_Δ))
    Re = significant_diameter*speed/kinematic_viscosity_itp(uconvert(°F, temperature_air ))
    c_p = specific_heat_wet_air(atmospheric_pressure, humidity_air)
    μ = dynamic_viscosity_itp(uconvert(°F, temperature_air))
    k = air_thermal_conductivity_itp(uconvert(°C, temperature_air))
    Pr = μ * c_p / k
    Nu = Nu_cylinder(Re,Pr)
    return Nu/significant_diameter*k
end
"""
`heat_into_humans(temperature_air::Temperature, temperature_room::Temperature, pressure_humidity::Pressure, temperature_stove::Temperature, pressure_Δ, scenario::SaunaScenario)::Power`
This function estimates heat entering a human from air, rooom, and stove temperatures, as well as humidity and change in humidity.
Radiation exchange with the room and the stove is computed, as well as convection with the air. A major component is estimating the convection coefficent. 
Evaporative cooling is also estimated, and deducted from the total heat transfer
Skin surface temperature is assumed to be the normal core body temperature.
"""
function heat_into_humans(temperature_air::Temperature, temperature_room::Temperature, pressure_humidity::Pressure, temperature_stove::Temperature, pressure_Δ, scenario::SaunaScenario)::Power
    stove_vf = outer_surface_area(scenario.sauna.stove)/4/outer_surface_area(scenario.sauna.room)
    radiation_with_room = radiance_exchange(temperature_air, body_temperature, body_surface_area*(1-stove_vf)*view_factor_external_body_naked)
    radiation_with_stove = radiance_exchange(temperature_stove, body_temperature, body_surface_area*stove_vf*view_factor_external_body_naked)
    effective_body_convective_coeff = compute_effective_convection_coeff(pressure_Δ,temperature_air,pressure_humidity, scenario.atmospheric_pressure)
    convection_with_room = convection_exchange(temperature_air, body_temperature, body_surface_area, effective_body_convective_coeff )
    evap_cooling = evaporation_cooling(temperature_air, pressure_humidity)
    return radiation_with_room+radiation_with_stove+convection_with_room-evap_cooling
end

function heat_into_humans(results::SaunaResults, scenario::SaunaScenario)
    pressure_itp = interpolate((results.times,), results.pressures_humidity, Gridded(Linear()))
    pressures_Δ = map(time->Interpolations.gradient(pressure_itp,time)[1], results.times)
    map(results.temperatures_air, results.temperatures_room, results.pressures_humidity, results.temperatures_stove, pressures_Δ) do temperature_air, temperature_room, pressure_humidity, temperature_stove, pressure_Δ
        heat_into_humans(temperature_air, temperature_room, pressure_humidity, temperature_stove, pressure_Δ,scenario)
    end
end
function find_human_temperature(human_heat_input::Vector{<:Power}, human_exper_temperatures::Vector{<:Temperature}, times::Vector{<:Time}, air_temperature_start_throwing::Temperature)
    idx_start = findfirst(temperature -> temperature > air_temperature_start_throwing, human_exper_temperatures)
    idx_start = max(2, idx_start)
    current_temperature = body_core_temperature
    temperature_core = map(idx_start:length(times)) do idx_temperature
        current_temperature = current_temperature + human_heat_input[idx_temperature] * (times[idx_temperature] - times[idx_temperature-1])/(body_mass* body_specific_heat)
    end
    times_temperature_core = map(idx -> times[idx], idx_start:length(times))
    return temperature_core, times_temperature_core
end