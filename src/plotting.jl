function plot_starmap(stars::Array{Star{EquatorialCoordinates}},
                      local_civilian_date::ZonedDateTime, 
                      latlong::LatLng;
                      projection=stereographic_projection,
                      kwargs...)
  stars = [Star(equatorial_to_horizon(star.coordinates, local_civilian_date, latlong), star.magnitude) for star in stars]
  filter!(s -> s.coordinates.h >= 0, stars)
  plot_starmap(stars; projection=projection, kwargs...)
end

function plot_starmap(stars::Array{Star{HorizonCoordinates}}; projection=stereographic_projection, kwargs...)
  Data = Matrix{Float64}(undef, length(stars), 2)

  [Data[i,:] = projection(star.coordinates) for (i,star) in enumerate(stars)]
  
  scatter(
    Data[:,1],
    Data[:,2];
    color="#fff",
    background_color="#222",
    aspect_ratio=:equal,
    markersize=[magnitude_to_radius(star.magnitude) for star in stars],
    alpha=[magnitude_to_alpha(star.magnitude) for star in stars],
    grid=false,
    showaxis=false,
    legend=false,
    kwargs...
  )

  # cardinal points
  cardinalpos = 1.05
  cardinalcolor = "#555"
  annotate!(0, cardinalpos, "N", cardinalcolor)
  annotate!(0, -cardinalpos, "S", cardinalcolor)
  annotate!(cardinalpos, 0, "W", cardinalcolor)
  annotate!(-cardinalpos, 0, "E", cardinalcolor)

  # map outline
  tvec = range(0, 4π, length = 500)
  plot!(sin.(tvec), cos.(tvec), color="#191919")
end

function magnitude_to_radius(magnitude::Real; maxmag=8)
  0.15 * 1.35^(maxmag - magnitude)
end

function magnitude_to_alpha(magnitude::Real; maxmag=8)
  magnitude_to_radius(magnitude; maxmag)
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