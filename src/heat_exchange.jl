"""
Provides an estimate of the raidance power transmitted to a stove in a small fire.
"""
function radiance_exchange(temperature_1::Temperature, temperature_2::Temperature, area::Area, emissivity=1)::Power
    emissivity * uconvert(W, σ * (uconvert(K,temperature_1) - uconvert(K, temperature_2))^4 * uconvert(m^2, area) )
end
function convection_exchange(temperature_1::Temperature, temperature_2::Temperature, area::Area, convective_coeff )::Power
    uconvert(W,convective_coeff*(uconvert(K,temperature_1)-uconvert(K,temperature_2)) * area)
end 
function conduction_exchange_wall(temperature_room::Temperature, temperature_outside::Temperature, room::Room)::Power
    uconvert(W, (uconvert(K,temperature_room) - uconvert(K, temperature_outside))*outer_surface_area(room)/room.thickness_insulation*room.conduction_coeff)
end
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