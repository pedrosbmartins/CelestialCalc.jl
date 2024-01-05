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