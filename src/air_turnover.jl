const compared_house_surface_area = 50m^2 + 7m*8m*3 #approximation, three sides open, 50m^2 floors.
const compared_house_volume = 400m^3 #given
"""
Diffusion of air:
https://www.nature.com/articles/7500229
A house was shown to have a turnover rate of .176 + .0162 ΔT
"""
function air_turnover(temperature_difference::Temperature, room::Room)::Frequency
    room_surface_area_to_volume = outer_surface_area(room)/volume(room)
    sauna_term_factor = room_surface_area_to_volume/(compared_house_surface_area/compared_house_volume)
    #constants come from https://www.nature.com/articles/7500229
    sauna_term_factor*(.176*hr^-1 + .0162/(hr*K)*uconvert(K,temperature_difference))
end