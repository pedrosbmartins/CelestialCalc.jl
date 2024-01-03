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

struct Angle
  degrees::Integer
  minutes::Integer
  seconds::Float64
  isnegative::Bool
end

Angle(x) = Angle(x,0,0)
Angle(x,y) = Angle(x,y,0)
Angle(x,y,z) = Angle(x,y,z,false)
Angle(x,isneg::Bool) = Angle(x,0,0,isneg)
Angle(x,y,isneg::Bool) = Angle(x,y,0,isneg)

function Base.show(io::IO, angle::Angle)
  (; degrees, minutes, seconds, isnegative) = angle
  sign = isnegative ? "-" : ""
  minutes = lpad(minutes,2,"0")
  seconds = Printf.@sprintf("%05.2f", seconds)
  print(io, "$(sign)$(degrees)°$(minutes)'$(seconds)''")
end

function angle_to_decimal(angle::Angle)
  (; degrees, minutes, seconds, isnegative) = angle
  sign = isnegative ? -1 : 1
  decimal_minutes = seconds / 60
  total_minutes = minutes + decimal_minutes
  decimal_degrees = total_minutes / 60
  total_degrees = abs(degrees) + decimal_degrees
  return sign * total_degrees
end

function time_to_decimal(time::Time)
  hours = Dates.hour(time)
  minutes = Dates.minute(time)
  seconds = Dates.second(time)
  milliseconds = Dates.millisecond(time)
  return angle_to_decimal(Angle(hours, minutes, seconds + 0.001*milliseconds))
end

function decimal_to_angle(decimal::Float64)
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

function decimal_to_time(decimal::Float64)
  (; degrees, minutes, seconds) = decimal_to_angle(decimal)
  milliseconds, seconds = modf(seconds)
  return Time(degrees, minutes, trunc(seconds), trunc(1000*milliseconds))
end

function local_to_universal_time(zdt::ZonedDateTime)
  return astimezone(zdt, tz"UTC")
end

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

function prime_to_local_sidereal_time(prime_sidereal_time::Float64, longitude::Float64)
  adjust = longitude / 15
  local_sidereal_time = prime_sidereal_time + adjust
  local_sidereal_time < 0 && (local_sidereal_time += 24)
  local_sidereal_time >= 24 && (local_sidereal_time -= 24)
  return local_sidereal_time
end

function local_civilian_to_sidereal_time(lct::ZonedDateTime, longitude::Float64)
  return lct |> solar_to_prime_sidereal_time |> (t -> prime_to_local_sidereal_time(t, longitude))
end

# Coordinate Systems

struct LatLng
  latitude::Float64
  longitude::Float64
end

struct EquatorialCoordinates
  α::Time
  δ::Float64
end

function Base.show(io::IO, ec::EquatorialCoordinates)
  (; α, δ) = ec
  print(io, "EquatorialCoordinates α=$α δ=$(decimal_to_angle(δ))")
end

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

function equatorial_to_horizon(δ::Float64, hour_angle::Time, latitude::Float64)
  return equatorial_to_horizon(δ, time_to_decimal(hour_angle), latitude)
end

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

function equatorial_to_horizon(eqcoord::EquatorialCoordinates, local_civilian_date::ZonedDateTime, latlong::LatLng)
  (; α, δ) = eqcoord
  (; latitude, longitude) = latlong

  local_sidereal_time = local_civilian_to_sidereal_time(local_civilian_date, longitude)
  H = local_sidereal_time - time_to_decimal(α)
  (H < 0) && (H = H + 24)

  return equatorial_to_horizon(δ, H, latitude)
end

function cartesian_projection(hcoords::HorizonCoordinates)
  (; h, Az) = hcoords
  x = cosd(h)sind(Az)
  y = cosd(h)cosd(Az)
  z = sind(h)
  return [x,y,z]
end

function stereographic_projection(hcoords::HorizonCoordinates)
  x,y,z = cartesian_projection(hcoords)

  x = x / (z + 1)
  y = y / (z + 1)

  # invert East/West, normalize to [-1, 1]
  x = (1 - x) - 1

  return [x,y]
end

# Plotting

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
    stars,
    local_civilian_date,
    latlong;
    projection=projection,
    sizeeffect=sizeeffect,
    alphaeffect=alphaeffect,
    kwargs...)
end

function plot_starmap(stars::Array{Star{HorizonCoordinates}},
                      local_civilian_date::ZonedDateTime,
                      latlong::LatLng;
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
