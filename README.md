# SaunaModel
This package is estimate of how a lumped sum sauna would behave. A lumped sum system modeling means approximating each component of the system with one number. This is a rough and ready approximation: obviously, the stove isn't all one temperature, and the air has has a very complex fluid dynamics problem, which could heat a small sized sauna with the heat given off with all the computers needed to solve in granular detail.

You might ask why would I sink the time into modelling a sauna with differential equations. It sprung from a group chat where we were discussing the impact of adding a water tank to a sauna. I fired off some real preliminary calculations, then said I didn't have the time to write up the differential equations to do it right. The problem stuck with me, and I figured I had enough discussions abouth the thermal dynamics of a sauna to bump out a solution.

## Modelling the Sauna

### Components
Elements of the sauna include
- Fire
- Stove
- Air temperature
- Air humidity
- Walls and furniture of the room
- Floor of the sauna
- Air outside (both temperature and humidity)
- Mass of water on stove
- Temperature of water on stove

There are many other possible variables to consider, such as the effect of adding a water heater.
### Boundary Conditions
One way to make the system simpiler to deal with is to assume a constant value for some components of the system, and to drive some components with functions. In the default scenario:
- Floor of sauna is assumed to be 50 °F
- Outside temperature is assumed to be 50 °F
- Outside relative humidity is 30%
- The fire grows to a maximum temperature of 1200°F and a radius of .3 meters

### Heat transfer equations
Here is a short review of heat transfer. There are only a few equations that drive this process. For all equations below <img src="/tex/53d147e7f3fe6e47ee05b88b166bd3f6.svg?invert_in_darkmode&sanitize=true" align=middle width=12.32879834999999pt height=22.465723500000017pt/> is area, <img src="/tex/ddcb483302ed36a59286424aa5e0be17.svg?invert_in_darkmode&sanitize=true" align=middle width=11.18724254999999pt height=22.465723500000017pt/> is length, <img src="/tex/2f118ee06d05f3c2d98361d9c30e38ce.svg?invert_in_darkmode&sanitize=true" align=middle width=11.889314249999991pt height=22.465723500000017pt/> is temperature.
#### Conduction
Conduction is when heat moves through physical contact with objects. In the sauna, the main conductive aspect is the walls conducting temperature to the outside. Effective insulation will greatly reduce this mode of heat transfer.
<p align="center"><img src="/tex/eec24de8f2f19d3dc7e84014aec0f1d6.svg?invert_in_darkmode&sanitize=true" align=middle width=119.69004134999999pt height=34.7253258pt/></p>
where <img src="/tex/63bb9849783d01d91403bc9a5fea12a2.svg?invert_in_darkmode&sanitize=true" align=middle width=9.075367949999992pt height=22.831056599999986pt/> is the conduction coefficient, which is fairly straight forward to measure for many materials. To learn all you probably need to know about thermal conduction consult [Wikipedia.](https://en.wikipedia.org/wiki/Thermal_conduction)

#### Convection
Convection is the mode of heat transfer due to fluid flows. This mode of heat transfer is extremely common in a sauna. The heat transfer from a burning hot steam to your shoulders is one. Heat transfer from hot gas rising off the fire to the stove is another.
<p align="center"><img src="/tex/0f64a80e50d869dc0cfbd2eadaca9855.svg?invert_in_darkmode&sanitize=true" align=middle width=118.11319574999999pt height=16.438356pt/></p>
where <img src="/tex/2ad9d098b937e46f9f58968551adac57.svg?invert_in_darkmode&sanitize=true" align=middle width=9.47111549999999pt height=22.831056599999986pt/> is the convective coefficient. Convective coefficients can be approximated through a fairly complex process of determining Reynold's numbers and Nusselt's numbers. I used reference numbers to save time. To learn all you probably need to know about thermal convection consult [Wikipedia.](https://en.wikipedia.org/wiki/Convective_heat_transfer)

#### Radiation
Radiation is the mode of heat transfer due to electromagnetic radiation. Heat moving like light, instantaneously, through the atmosphere. If you feel the heat coming off of something hot, it is probably radiation. The burning sensation in your shins from an oversized stove (cough, Benda's, cough) is from radiation.
<p align="center"><img src="/tex/c2450948984f2451cba46b546ad61778.svg?invert_in_darkmode&sanitize=true" align=middle width=125.2973535pt height=18.312383099999998pt/></p>
where <img src="/tex/8cda31ed38c6d59d14ebefa440099572.svg?invert_in_darkmode&sanitize=true" align=middle width=9.98290094999999pt height=14.15524440000002pt/> is the Stefan–Boltzmann constant (some universal constant), <img src="/tex/7ccca27b5ccc533a2dd72dc6fa28ed84.svg?invert_in_darkmode&sanitize=true" align=middle width=6.672392099999992pt height=14.15524440000002pt/> is the emissivity (black top has a high emissivity, white shirts have a lower one). I assumed that <img src="/tex/c2101b156b66aec18d423619f4e227b5.svg?invert_in_darkmode&sanitize=true" align=middle width=36.80923124999999pt height=21.18721440000001pt/> for the purposes of this model. [Wikipedia.](https://en.wikipedia.org/wiki/Thermal_radiation)

#### Advection (mass transfer)
Heat is also transfered when hot air leaves the room and cold air flows in. Since our sauna is not leak proof, a certain amount of the air in the room turns over on every time increment. This  rate is associated with the difference in air temperature. [Nature](https://www.nature.com/articles/7500229) had a fairly solid article on the turnover rate for a house, and I adjusted (upwards) it for the surface area to volume ratio of the sauna under consideration. All smaller rooms have a larger surface area to volume ratio compared to larger rooms.
#### Phase change
Throwing water on the stove causes heat to convect into the water on the stove rapidly turning it into steam. This phase change heats the air and stings your ears. Since this is also a mass transfer, it is also advection. The steam coming off the stove is assumed to be 212°F as there will be minimal heating of the steam after it boils.
### Differential Equations
There are 6 differential equations modelling sauna dynamics. 4 of them are temperature (stove, air, room, thrown water), 1 of them is room humidity, and 1 is the mass of unboiled water that was thrown on the stove. There is also a jump step, which causes steam to be thrown. The mass of water suddenly increases on the stove, and rebalances the average temperature of the thrown water.
<center>

|Interaction| Fire | Stove | Air | Room | Thrown water | Human |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|Fire | - | Convection and <br> Radiation | - | - | - | - |
|Stove | - | - | Convection | Radiation | Convection | Radiation |
|Air | - | - |  | Convection | - | Convection <br> Evaporation |
|Room | - | - |  | Convection | - | Radiation |

</center>


## Humans in the Sauna

## Commentary on development
I developed the model in Julia for a couple of reasons. First, it is my daily driver language, it is what I use all the time. It also offers some excellent unit and differential equations packages. I used a functional approach as far as possible, avoiding side effects other than what is dictated by the Differential Equations package. This should make the code base easier to maintain.
