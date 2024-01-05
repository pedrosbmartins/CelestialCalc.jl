import JSON

"""
    Star

Represent a star object and its data (coordinate and magnitude).
"""
struct Star{C<:Union{EquatorialCoordinates,HorizonCoordinates}}
  coordinates::C
  magnitude::Float64
end

"""
    brightstars_catalog

Loads the Bright Stars catalog in JSON format as a list of [`Star`](@ref) with [`EquatorialCoordinates`](@ref).
"""
function brightstars_catalog()
  filename = "$(pkgdir(@__MODULE__))/data/BSC.json"
  catalog = JSON.parsefile(filename)
  [parsestar(star) for star in catalog]
end

function parsestar(star)
  α = parse_α(star["RA"])
  δ = parse_δ(star["DEC"])
  mag = parse(Float64, star["MAG"])
  return Star(EquatorialCoordinates(α,δ),mag)
end

function parse_α(input)
  (h, m, s) = map(x -> parse(Float64, x), split(input, ":"))
  (mi,s) = modf(s)
  return Time(h,m,s,round(mi*1000))
end

function parse_δ(input)
  (deg,m,s) = map(x -> parse(Float64, x), split(input, ":"))
  dec = Angle(abs(deg), m, s, deg < 0)
  return angle_to_decimal(dec)
end
