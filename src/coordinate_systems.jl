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
