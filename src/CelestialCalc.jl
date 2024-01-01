module CelestialCalc

using Dates
using Printf
using TimeZones

export Angle
export angle_to_decimal, time_to_decimal, decimal_to_angle, decimal_to_time
export local_to_universal_time, solar_to_prime_sidereal_time, prime_to_local_sidereal_time, local_civilian_to_sidereal_time

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

end # module CelestialCalc
