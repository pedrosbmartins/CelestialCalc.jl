module CelestialCalc

using Dates, Printf
using Plots, TimeZones

export Angle
export angle_to_decimal, time_to_decimal, decimal_to_angle, decimal_to_time
export local_to_universal_time, solar_to_prime_sidereal_time, prime_to_local_sidereal_time, local_civilian_to_sidereal_time
export LatLng, EquatorialCoordinates, HorizonCoordinates
export equatorial_to_horizon
export cartesian_projection, stereographic_projection
export Star, MagnitudeEffect, plot_starmap

"""
    Angle

Represents an angle with degrees, minutes and seconds. The `isnegative` flag
is used instead of allowing `degrees` to be negative for better dealing
with negative angles smaller than 1 (example: *-0°10'10''*).

# Examples
```jldoctest
julia> Angle(10,5,30)
10°05'30.00''

julia> Angle(45,15,2,true)
-45°15'02.00''

julia> Angle(270,55,2.1)
270°55'02.10''
```
"""
struct Angle
  degrees::Integer
  minutes::Integer
  seconds::Real
  isnegative::Bool
end

"""
    Angle(d, isneg::Bool=false) -> Angle

Construct an angle with whole degrees.

# Examples
```jldoctest
julia> Angle(10)
10°00'00.00''

julia> Angle(45,true)
-45°00'00.00''
```
"""
Angle(d, isneg::Bool=false) = Angle(d, 0, 0.0, isneg)

"""
    Angle(d, m, isneg::Bool=false) -> Angle

Construct an angle with whole degrees and minutes.

# Examples
```jldoctest
julia> Angle(10,5)
10°05'00.00''

julia> Angle(45,15,true)
-45°15'00.00''
```
"""
Angle(d,m,isneg::Bool=false) = Angle(d,m,0,isneg)

"""
    Angle(d, m, s::Real) -> Angle

Shorthand for the construction of positive angles.

# Examples
```jldoctest
julia> Angle(10,5,30)
10°05'30.00''

julia> Angle(45,15,2.1)
45°15'02.10''
```
"""
Angle(d,m,s::Real) = Angle(d,m,s,false)

function Base.show(io::IO, angle::Angle)
  (; degrees, minutes, seconds, isnegative) = angle
  sign = isnegative ? "-" : ""
  minutes = lpad(minutes,2,"0")
  seconds = Printf.@sprintf("%05.2f", seconds)
  print(io, "$(sign)$(degrees)°$(minutes)'$(seconds)''")
end

"""
    angle_to_decimal(angle::Angle)

Convert Angle in DMS format to a decimal.
"""
function angle_to_decimal(angle::Angle)
  (; degrees, minutes, seconds, isnegative) = angle
  sign = isnegative ? -1 : 1
  decimal_minutes = seconds / 60
  total_minutes = minutes + decimal_minutes
  decimal_degrees = total_minutes / 60
  total_degrees = abs(degrees) + decimal_degrees
  return sign * total_degrees
end

"""
    time_to_decimal(time::Time)

Convert Time to a decimal.
"""
function time_to_decimal(time::Time)
  hours = Dates.hour(time)
  minutes = Dates.minute(time)
  seconds = Dates.second(time)
  milliseconds = Dates.millisecond(time)
  return angle_to_decimal(Angle(hours, minutes, seconds + 0.001*milliseconds))
end

"""
    decimal_to_angle(decimal::Real)

Convert a decimal value to an [`Angle`](@ref) in DMS format.
"""
function decimal_to_angle(decimal::Real)
  # TODO: handle cases where minutes is ~59.999 and rounds to 60
  abs_decimal = abs(decimal)
  degrees = trunc(Int, abs_decimal)
  frac_abs_decimal, _ = modf(abs_decimal)
  decimal_minutes = 60 * frac_abs_decimal
  minutes = trunc(Int, decimal_minutes)
  decimal_minutes_frac, _ = modf(decimal_minutes)
  decimal_seconds = 60 * decimal_minutes_frac
  seconds = round(decimal_seconds; digits=2)
  return Angle(degrees, minutes, seconds, decimal < 0)
end

"""
    decimal_to_time(decimal::Real)

Convert a decimal value to a Time object.
"""
function decimal_to_time(decimal::Real)
  (; degrees, minutes, seconds) = decimal_to_angle(decimal)
  milliseconds, seconds = modf(seconds)
  return Time(degrees, minutes, trunc(seconds), trunc(1000*milliseconds))
end

"""
    local_to_universal_time(zdt::ZonedDateTime) -> ZonedDateTime

Convert a ZonedDateTime in any timezone to the `UTC` timezone.
"""
function local_to_universal_time(zdt::ZonedDateTime)
  return astimezone(zdt, tz"UTC")
end

"""
    solar_to_prime_sidereal_time(zdt::ZonedDateTime) -> Real

Convert a ZonedDateTime to its equivalent GMST (Greenwich Mean Sidereal Time).
"""
function solar_to_prime_sidereal_time(zdt::ZonedDateTime)
  ut = local_to_universal_time(zdt)
  year = Dates.year(Date(ut))
  ut_0h = ZonedDateTime(Date(ut), tz"UTC")
  JD = datetime2julian(DateTime(ut_0h))
  JD₀ = datetime2julian(DateTime(year,1,1))
  days = JD - JD₀
  T = (JD₀ - 2_415_020.0) / 36_525.0
  R = 6.6460656 + 2400.051262T + 0.00002581T^2
  B = 24 - R + 24(year - 1900)
  T₀ = 0.0657098days - B
  UT = time_to_decimal(Time(ut))
  GST = T₀ + 1.002738UT
  GST < 0 && (GST += 24)
  GST >= 24 && (GST -= 24)
  return GST
end

"""
    prime_to_local_sidereal_time(prime_sidereal_time::Float64, longitude::Float64) -> Float64

Find an observer's local sidereal time by adjusting prime sidereal time to its longitude.
"""
function prime_to_local_sidereal_time(prime_sidereal_time::Float64, longitude::Float64)
  adjust = longitude / 15
  local_sidereal_time = prime_sidereal_time + adjust
  local_sidereal_time < 0 && (local_sidereal_time += 24)
  local_sidereal_time >= 24 && (local_sidereal_time -= 24)
  return local_sidereal_time
end

"""
    local_civilian_to_sidereal_time(lct::ZonedDateTime, longitude::Float64) -> Float64

Convert an observer's local civilian date and time (as a `ZonedDateTime`) to its corresponding local sidereal time (in decimal format).
"""
function local_civilian_to_sidereal_time(lct::ZonedDateTime, longitude::Float64)
  return lct |> solar_to_prime_sidereal_time |> (t -> prime_to_local_sidereal_time(t, longitude))
end

# Coordinate Systems

"""
    LatLng

Coordinate system for locating a point in Earth's surface.
"""
struct LatLng
  latitude::Float64
  longitude::Float64
end

"""
    EquatorialCoordinates

Coordinate system for locating a point in the celestial sphere, given fixed points of reference (the celestial equator and
the First Point of Aries). Here, `α` is right-ascention and `δ` is declination.
"""
struct EquatorialCoordinates
  α::Time
  δ::Float64
end

function Base.show(io::IO, ec::EquatorialCoordinates)
  (; α, δ) = ec
  print(io, "EquatorialCoordinates α=$α δ=$(decimal_to_angle(δ))")
end

"""
    HorizonCoordinates

Coordinate system for locating a point in an observer's local celestial sphere, which varies with time. Here, `h` is altitude
and `Az` is azimuth.
"""
struct HorizonCoordinates
  h::Float64
  Az::Float64
end

function Base.isapprox(hc1::HorizonCoordinates, hc2::HorizonCoordinates; kwargs...)
  return isapprox(hc1.h, hc2.h; kwargs...) && isapprox(hc1.Az, hc2.Az; kwargs...)
end

function Base.show(io::IO, hc::HorizonCoordinates)
  (; h, Az) = hc
  print(io, "HorizonCoordinates h=$(decimal_to_angle(h)) Az=$(decimal_to_angle(Az))")
end

"""
    equatorial_to_horizon(δ::Float64, hour_angle::Time, latitude::Float64) -> HorizonCoordinates

Find the [`HorizonCoordinates`](@ref) for an object, given its declination (δ) and hour angle (H) represented as a `Time` object,
as well as the observer's latitude.
"""
function equatorial_to_horizon(δ::Float64, hour_angle::Time, latitude::Float64)
  return equatorial_to_horizon(δ, time_to_decimal(hour_angle), latitude)
end

"""
    equatorial_to_horizon(δ::Float64, hour_angle::Float64, latitude::Float64) -> HorizonCoordinates

Find the [`HorizonCoordinates`](@ref) for an object, given its declination (δ) and hour angle (H) represented in decimal format,
as well as the observer's latitude.
"""
function equatorial_to_horizon(δ::Float64, hour_angle::Float64, latitude::Float64)
  Φ = latitude
  H_deg = 15hour_angle

  # altitude h
  sind_h = sind(δ)sind(Φ) + cosd(δ)cosd(Φ)cosd(H_deg)
  h = asind(sind_h)

  # azimuth Az
  cos_Az = (sind(δ) - sind(Φ)sind_h) / (cosd(Φ)cosd(h))
  Az = acosd(cos_Az)

  # azimuth adjustment
  (sind(H_deg) > 0) && (Az = 360 - Az)

  return HorizonCoordinates(h, Az)
end

"""
    equatorial_to_horizon(eqcoord::EquatorialCoordinates, local_civilian_date::ZonedDateTime, latlong::LatLng) -> HorizonCoordinates

Find the [`HorizonCoordinates`](@ref) for an object, given its [`EquatorialCoordinates`](@ref) and the observer's local civilizan time and position.
"""
function equatorial_to_horizon(eqcoord::EquatorialCoordinates, local_civilian_date::ZonedDateTime, latlong::LatLng)
  (; α, δ) = eqcoord
  (; latitude, longitude) = latlong

  local_sidereal_time = local_civilian_to_sidereal_time(local_civilian_date, longitude)
  H = local_sidereal_time - time_to_decimal(α)
  (H < 0) && (H = H + 24)

  return equatorial_to_horizon(δ, H, latitude)
end

"""
    cartesian_projection(hcoords::HorizonCoordinates) -> [Float64,Float64,Float64]

Project [`HorizonCoordinates`](@ref) to the Cartesian coordinate system.
"""
function cartesian_projection(hcoords::HorizonCoordinates)
  (; h, Az) = hcoords
  x = cosd(h)sind(Az)
  y = cosd(h)cosd(Az)
  z = sind(h)
  return [x,y,z]
end

"""
    cartesian_projection(hcoords::HorizonCoordinates) -> [Float64,Float64,Float64]

Project [`HorizonCoordinates`](@ref) to the 2-dimensional Cartesian coordinate system using the stereographic projection.
"""
function stereographic_projection(hcoords::HorizonCoordinates)
  x,y,z = cartesian_projection(hcoords)

  x = x / (z + 1)
  y = y / (z + 1)

  # invert East/West, normalize to [-1, 1]
  x = (1 - x) - 1

  return [x,y]
end

# Plotting

"""
    Star

Represent a star object and its data (coordinate and magnitude).
"""
struct Star{C<:Union{EquatorialCoordinates,HorizonCoordinates}}
  coordinates::C
  magnitude::Float64
end

struct MagnitudeEffect
  min::Float64
  factor::Float64
  exp::Float64
end

function magnitude_effect(value::Float64, effect::MagnitudeEffect; minvalue=2, maxvalue=8)
  (; min, factor, exp) = effect
  min + factor * (1 - (value + minvalue)/(maxvalue + minvalue))^exp
end

function plot_starmap(stars::Array{Star{EquatorialCoordinates}},
                      local_civilian_date::ZonedDateTime, 
                      latlong::LatLng;
                      projection=stereographic_projection,
                      sizeeffect=MagnitudeEffect(0.5,3,4),
                      alphaeffect=MagnitudeEffect(0,5,4),
                      kwargs...)
  stars = [Star(equatorial_to_horizon(star.coordinates, local_civilian_date, latlong), star.magnitude) for star in stars]
  filter!(s -> s.coordinates.h >= 0, stars)
  plot_starmap(
    stars;
    projection=projection,
    sizeeffect=sizeeffect,
    alphaeffect=alphaeffect,
    kwargs...)
end

function plot_starmap(stars::Array{Star{HorizonCoordinates}};
                      projection=stereographic_projection,
                      sizeeffect=MagnitudeEffect(0.5,3,4),
                      alphaeffect=MagnitudeEffect(0,5,4),
                      kwargs...)
  Projection = Matrix{Float64}(undef, length(stars), 2)

  [Projection[i,:] = projection(star.coordinates) for (i,star) in enumerate(stars)]

  scatter(
    Projection[:,1],
    Projection[:,2];
    color="#fff",
    background_color="#222",
    aspect_ratio=:equal,
    alpha=[magnitude_effect(star.magnitude, alphaeffect) for star in stars],
    markersize=[magnitude_effect(star.magnitude, sizeeffect) for star in stars],
    grid=false,
    showaxis=false,
    legend=false,
    kwargs...
  )

  # map outline
  tvec = range(0, 4π, length = 500)
  plot!(sin.(tvec), cos.(tvec), color="#191919")
end

end # module CelestialCalc
