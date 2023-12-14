module CelestialCalc

using Printf

export DMS, HMS
export dms_to_decimal, hms_to_decimal, decimal_to_dms, decimal_to_hms

struct DMS
  degrees::Integer
  minutes::Integer
  seconds::Float64
  isnegative::Bool
end

DMS(x,y,z) = DMS(x,y,z,false)

struct HMS
  hours::Integer
  minutes::Integer
  seconds::Float64
end

function Base.show(io::IO, dms::DMS)
  (; degrees, minutes, seconds, isnegative) = dms
  sign = isnegative ? "-" : ""
  minutes = lpad(minutes,2,"0")
  seconds = Printf.@sprintf("%05.2f", seconds)
  print(io, "$(sign)$(degrees)°$(minutes)'$(seconds)''")
end

function Base.show(io::IO, hms::HMS)
  (; hours, minutes, seconds) = hms
  hours = lpad(hours,2,"0")
  minutes = lpad(minutes,2,"0")
  seconds = Printf.@sprintf("%05.2f", seconds)
  print(io, "$(hours):$(minutes):$(seconds)")
end

function dms_to_decimal(dms::DMS)
  (; degrees, minutes, seconds, isnegative) = dms
  sign = isnegative ? -1 : 1
  decimal_minutes = seconds / 60
  total_minutes = minutes + decimal_minutes
  decimal_degrees = total_minutes / 60
  total_degrees = abs(degrees) + decimal_degrees
  return sign * total_degrees
end

function hms_to_decimal(hms::HMS)
  (; hours, minutes, seconds) = hms
  return dms_to_decimal(DMS(hours, minutes, seconds))
end

function decimal_to_dms(decimal::Float64)
  # todo: handle cases where minutes is ~59.999 and rounds to 60
  isnegative = decimal < 0 ? true : false
  abs_decimal = abs(decimal)
  degrees = trunc(Int, abs_decimal)
  frac_abs_decimal, _ = modf(abs_decimal)
  decimal_minutes = 60 * frac_abs_decimal
  minutes = trunc(Int, decimal_minutes)
  decimal_minutes_frac, _ = modf(decimal_minutes)
  decimal_seconds = 60 * decimal_minutes_frac
  seconds = round(decimal_seconds; digits=2)
  return DMS(degrees, minutes, seconds, isnegative)
end

function decimal_to_hms(decimal::Float64)
  (; degrees, minutes, seconds) = decimal_to_dms(decimal)
  return HMS(degrees, minutes, seconds)
end

end # module CelestialCalc
