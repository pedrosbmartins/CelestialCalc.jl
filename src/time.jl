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