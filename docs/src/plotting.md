# Plotting

Utilities for plotting star maps.

## Recipe

CelestialCalc supplies a [Plots.jl](https://github.com/JuliaPlots/Plots.jl) recipe for plotting a list of [`Star{HorizonCoordinates}`](@ref).

### Example

```julia
using Plots

central_star = Star(coordinates=HorizonCoordinates(h=Angle(90),Az=Angle(0)),magnitude=1.0)
plot([star]; size=(900,800), colormode=:light)
```

### Arguments

- `projection=stereographic_projection`: a function that receives HorizonCoordinates and outputs a Cartesian projection `(x,y)`.
- `colormode=:light`: the color mode, either `:light` or `:dark`.

## Methods

```@docs
cartesian_projection
stereographic_projection
```
