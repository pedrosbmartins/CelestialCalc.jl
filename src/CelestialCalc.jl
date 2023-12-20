module CelestialCalc

using Dates
using Printf

export AngleDMS
export angle_to_decimal, time_to_decimal, decimal_to_angle, decimal_to_time

struct AngleDMS
  degrees::Integer
  minutes::Integer
  seconds::Float64
  isnegative::Bool
end

AngleDMS(x,y,z) = AngleDMS(x,y,z,false)

function Base.show(io::IO, angle::AngleDMS)
  (; degrees, minutes, seconds, isnegative) = angle
  sign = isnegative ? "-" : ""
  minutes = lpad(minutes,2,"0")
  seconds = Printf.@sprintf("%05.2f", seconds)
  print(io, "$(sign)$(degrees)°$(minutes)'$(seconds)''")
end

function angle_to_decimal(angle::AngleDMS)
  (; degrees, minutes, seconds, isnegative) = angle
  sign = isnegative ? -1 : 1
  decimal_minutes = seconds / 60
  total_minutes = minutes + decimal_minutes
  decimal_degrees = total_minutes / 60
  total_degrees = abs(degrees) + decimal_degrees
  return sign * total_degrees
end

function time_to_decimal(hms::Time)
  hours = Dates.value(Hour(hms))
  minutes = Dates.value(Minute(hms))
  seconds = Dates.value(Second(hms))
  return angle_to_decimal(AngleDMS(hours, minutes, seconds))
end

function decimal_to_angle(decimal::Float64)
  # todo: handle cases where minutes is ~59.999 and rounds to 60
  abs_decimal = abs(decimal)
  degrees = trunc(Int, abs_decimal)
  frac_abs_decimal, _ = modf(abs_decimal)
  decimal_minutes = 60 * frac_abs_decimal
  minutes = trunc(Int, decimal_minutes)
  decimal_minutes_frac, _ = modf(decimal_minutes)
  decimal_seconds = 60 * decimal_minutes_frac
  seconds = round(decimal_seconds; digits=2)
  return AngleDMS(degrees, minutes, seconds, decimal < 0)
end

function decimal_to_time(decimal::Float64)
  (; degrees, minutes, seconds) = decimal_to_angle(decimal)
  milliseconds, seconds = modf(seconds)
  return Time(degrees, minutes, trunc(seconds), trunc(100*milliseconds))
end

end # module CelestialCalc
