module CelestialCalc

export DMS, HMS
export dms_to_decimal, hms_to_decimal

struct DMS
  degrees::Integer
  minutes::Integer
  seconds::Integer
end

struct HMS
  hours::Integer
  minutes::Integer
  seconds::Integer
end

function dms_to_decimal(dms::DMS)
  (; degrees, minutes, seconds) = dms
  sign = degrees < 0 ? -1 : 1
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

end # module CelestialCalc
