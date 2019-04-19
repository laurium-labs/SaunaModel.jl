# Differential Equations

SaunaModel relies on the excellent [DifferentialEquations.jl](https://docs.juliadiffeq.org/latest/) to solve the sauna state. One particular challenge of modelling a sauna is the jump condition of throwing steam. DifferentialEquations handled it beautifully with a ```VariableRateJump``` problem. The ordinary differential equation part of the problem is described in ```build_sauna_model```.
```@docs
build_sauna_model
```
The jump problem posed by steam throwing is handled by ```throw_steam!```.
```@docs
throw_steam!
```
The rate of steam throwing is determined by ```steam_throwing```.
```@docs
steam_throwing
```
# Relations used
There are 6 differential equations modelling sauna dynamics. 4 of them are temperature (stove, air, room, thrown water), 1 of them is room humidity, and 1 is the mass of unboiled water that was thrown on the stove. There is also a jump step, which causes steam to be thrown. The mass of water suddenly increases on the stove, and rebalances the average temperature of the thrown water.

|Interaction| Fire | Stove | Air | Room | Thrown water | Human  (not interacting) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|Fire | - | Convection and 
 Radiation | - | - | - | - |
|Stove | - | - | Convection | Radiation | Convection | Radiation |
|Air | - | - |  | Convection | Phase Change | Convection Phase Change |
|Room | - | - |  | - | - | Radiation |

