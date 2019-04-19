"""
`radiance_exchange(temperature_1::Temperature, temperature_2::Temperature, area::Area, emissivity=1)::Power`
Provides an estimate of the raidance power transmitted between two heat sources with a certain area exposure.
"""
function radiance_exchange(temperature_1::Temperature, temperature_2::Temperature, area::Area, emissivity=1)::Power
    emissivity * uconvert(W, σ * (uconvert(K,temperature_1)^4 - uconvert(K, temperature_2)^4) * uconvert(m^2, area) )
end
"""
`convection_exchange(temperature_1::Temperature, temperature_2::Temperature, area::Area, convective_coeff )::Power`
Provides an estimate of convective power exchange on an area. Convection coefficient estimation is an important and difficult part of this.
"""
function convection_exchange(temperature_1::Temperature, temperature_2::Temperature, area::Area, convective_coeff )::Power
    uconvert(W,convective_coeff*(uconvert(K,temperature_1)-uconvert(K,temperature_2)) * area)
end 
"""
`conduction_exchange_wall(temperature_room::Temperature, temperature_outside::Temperature, room::Room)::Power`
Provides an estimate of heat loss through the walls of the sauna.
"""
function conduction_exchange_wall(temperature_room::Temperature, temperature_outside::Temperature, room::Room)::Power
    uconvert(W, (uconvert(K,temperature_room) - uconvert(K, temperature_outside))*outer_surface_area(room)/room.thickness_insulation*room.conduction_coeff)
end
room_mass(room::Room)::Mass = 380kg/m^3*(room.width*room.depth+room.height*room.width*2 +room.height*room.depth*2)*room.thickness_wall
heat_capacity(room::Room) = room_mass(room) * room.specific_heat
stove_mass(stove::Stove)::Mass = uconvert(kg, 7.83g/cm^3*stove.thickness_stove_wall*(outer_surface_area(stove) ))
rock_mass(stove::Stove)::Mass = uconvert(kg, 2.691*g/cm^3 *stove.width*stove.depth*.25*stove.height)
function heat_capacity(stove::Stove)
    stove_mass(stove) * stove.specific_heat + rock_mass(stove)*stove.rock_specific_heat
end
const steam_heat_capacity = 28.03J/(mol*K)
const dry_air_heat_capacity = 20.7643J/(mol*K)
function heat_capacity_wet_air(room::Room, atmospheric_pressure::Pressure, humidity_air::Pressure, temperature_air::Temperature) 
    #ideal gas law
    mol_dry_air = uconvert(mol, volume(room) * (atmospheric_pressure- humidity_air)/(uconvert(K,temperature_air)*R))
    mol_steam = uconvert(mol, volume(room) * (humidity_air)/(uconvert(K,temperature_air)*R))
    dry_air_heat_capacity*mol_dry_air + steam_heat_capacity * mol_steam
end

function specific_heat_wet_air(atmospheric_pressure::Pressure, humidity_air::Pressure)
    proportion_steam = humidity_air/(atmospheric_pressure)
    uconvert(J/(K*kg),proportion_steam*steam_heat_capacity / (18g/mol) + (1-proportion_steam)*dry_air_heat_capacity/(28.9647g/mol))
end