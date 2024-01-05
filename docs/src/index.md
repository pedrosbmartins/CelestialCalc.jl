# CelestialCalc.jl

A package that implements positional astronomy tools as described in the book [Celestial Calculations by J. L. Lawrence](https://celestialcalculations.github.io/).

CelestialCalc was created for (self-)educational purposes and its main goal is teaching myself positional astronomy in more depth. The package is made available as open source for anyone interested in amateur astronomy. Keep in mind that Julia already has a number of astronomy packages (many of them under the [JuliaAstro](https://juliaastro.org/dev/index.html) organization) that might be more fit for serious use.

## Library Outline

```@contents
Pages = ["angles.md", "coordinate_systems.md", "data.md", "plotting.md", "time.md"]
```

## Examples

### Finding horizon coordinates for a star

Given a star's equatorial coordinates (e.g. Betelgeuse in J2000) and an observer's local date/time and position,
find the object's horizon coordinates.

```jldoctest
julia> using CelestialCalc, Dates, TimeZones

julia> eq = EquatorialCoordinates(α=Time(5,55,10),δ=Angle(7,24,24))
EquatorialCoordinates α=05:55:10 δ=7°24'24.00''

julia> datetime = ZonedDateTime(2024,1,5,20,tz"UTC-3")
2024-01-05T20:00:00-03:00

julia> location = LatLng(-22.9068,-43.1729)
LatLng(-22.9068, -43.1729)

julia> hz = equatorial_to_horizon(eq, datetime, location)
HorizonCoordinates h=39°00'34.33'' Az=58°30'24.15''
```

### Plotting a star map

```@example 1
using CelestialCalc, TimeZones

brightstars = brightstars_catalog()

date = ZonedDateTime(2024,1,2,22,45,tz"UTC-3")
latlng = LatLng(-22.9068, -43.1729)

plot_starmap(brightstars, date, latlng; size=(900,800))
```
