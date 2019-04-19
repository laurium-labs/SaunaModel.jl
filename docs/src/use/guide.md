# Using SaunaModel

To use the sauna model, the first thing to be done is to contruct your model of the sauna. Consulting the default elements. This can be a bit exahustive to do from scratch.

```@docs
Stove
Room
SaunaNoWater
SteamThrowing
Fire
SaunaScenario
```
Then, you will want submit your solution to ```solve_sauna```, where the differential equations magic happens. 
```@docs
solve_sauna
```
It will then return a ```SaunaResults``` which can be parsed.
```@docs
SaunaResults
```
## Defaults

It takes quite a bit of legwork to track down all the correct parameters for a sauna. I kept some reasonable parameters in a file under `src/api/default_components.jl`. I would reccomend starting there if you want to edit a sauna from the commmand line.