module CelestialCalc

using Dates, Printf
using Plots, TimeZones

export Angle, angle_to_decimal, decimal_to_angle
export time_to_decimal, decimal_to_time
export local_to_universal_time, solar_to_prime_sidereal_time, prime_to_local_sidereal_time, local_civilian_to_sidereal_time
export LatLng, EquatorialCoordinates, HorizonCoordinates
export equatorial_to_horizon
export cartesian_projection, stereographic_projection
export Star, MagnitudeEffect, plot_starmap

include("Angle.jl")
include("time.jl")
include("coordinate_systems.jl")
include("plotting.jl")

end
