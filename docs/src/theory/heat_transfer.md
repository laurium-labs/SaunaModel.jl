### Heat transfer equations
Here is a short review of heat transfer. There are only a few equations that drive this process. For all equations below ``A`` is area, ``L`` is length, ``T`` is temperature in Kelvin.
#### Conduction
Conduction is when heat moves through physical contact with objects. In the sauna, the main conductive aspect is the walls conducting temperature to the outside. Effective insulation will greatly reduce this mode of heat transfer.
```math
k\frac{(T_{hot}-T_{cold})A}{L}
```
where ``k`` is the conduction coefficient, which is fairly straight forward to measure for many materials. To learn all you probably need to know about thermal conduction consult [Wikipedia.](https://en.wikipedia.org/wiki/Thermal_conduction).
In `SaunaModel` the only conduction computed is through the walls of the sauna.
```@docs
conduction_exchange_wall
```

#### Convection
Convection is the mode of heat transfer due to fluid flows. This mode of heat transfer is extremely common in a sauna. The heat transfer from a burning hot steam to your shoulders is one. Heat transfer from hot gas rising off the fire to the stove is another.
```math
h(T_{hot}-T_{cold})A
```
where ``h`` is the convective coefficient. Convective coefficients can be approximated through a fairly complex process of determining Reynold's numbers and Nusselt's numbers. I used reference numbers to save time. To learn all you probably need to know about thermal convection consult [Wikipedia.](https://en.wikipedia.org/wiki/Convective_heat_transfer)
In `SaunaModel` convection exchange is computed using `convection_exchange`.
```@docs
convection_exchange
```
#### Radiation
Radiation is the mode of heat transfer due to electromagnetic radiation. Heat moving like light, instantaneously, through the atmosphere. If you feel the heat coming off of something hot, it is probably radiation. The burning sensation in your shins from an oversized stove (cough, Benda's, cough) is from radiation.
```math
\sigma\epsilon A (T_{hot}^4 - T_{cold}^4)
```
where ``\sigma`` is the Stefan–Boltzmann constant (some universal constant), ``\epsilon`` is the emissivity (black top has a high emissivity, white shirts have a lower one). I assumed that ``\epsilon=1`` for the purposes of this model. [Wikipedia.](https://en.wikipedia.org/wiki/Thermal_radiation)
In `SaunaModel`, radiance exchange is computed using `radiance_exchange`.
```@docs
radiance_exchange
```
#### Advection (mass transfer)
Heat is also transfered when hot air leaves the room and cold air flows in. Since our sauna is not leak proof, a certain amount of the air in the room turns over on every time increment. This  rate is associated with the difference in air temperature. [Nature](https://www.nature.com/articles/7500229) had a fairly solid article on the turnover rate for a house, and I adjusted (upwards) it for the surface area to volume ratio of the sauna under consideration. All smaller rooms have a larger surface area to volume ratio compared to larger rooms. The mass exchange between the sauna and the outdoors is estimated in `air_turnover`.
```@docs
air_turnover
```
#### Phase change
Throwing water on the stove causes heat to convect into the water on the stove rapidly turning it into steam. This phase change heats the air and stings your ears. Since this is also a mass transfer, it is also advection. The steam coming off the stove is assumed to be 212°F as there will be minimal heating of the steam after it boils.