@kwdef struct GraphColor
  front::String
  back::String
end

const darktheme = GraphColor(front="#fff", back="#222")
const lighttheme = GraphColor(front="#222", back="#fff")

@recipe function plot_stars(stars::Vector{Star{HorizonCoordinates}}; projection=stereographic_projection, colormode=:light)
  Data = Matrix{Float64}(undef, length(stars), 2)
  [Data[i,:] .= projection(star.coordinates) for (i,star) in enumerate(stars)]

  color = colormode == :light ? lighttheme : darktheme

  seriestype := :scatter
  color := color.front
  background_color := color.back
  aspect_ratio := :equal
  markerstrokewidth := 0
  markersize := [magnitude_to_radius(star.magnitude) for star in stars]
  alpha := [magnitude_to_alpha(star.magnitude) for star in stars]
  grid := false
  showaxis := false
  legend := false

  # cardinal points
  @series begin
    cardinalpos = 1.01
    cardinalcolor = "#555"
    markersize := 0
    seriesalpha := 0
    series_annotation := [
      ("N", 6,  :center, :bottom, cardinalcolor, 8),
      ("S", 6,  :center, :top, cardinalcolor, 8),
      ("W", 6,  :left, :left, cardinalcolor, 8),
      ("E", 6,  :right, :right, cardinalcolor, 8),
    ]
    [(0,cardinalpos),(0,-cardinalpos),(cardinalpos,0),(-cardinalpos,0)]
  end

  # map outline
  @series begin
    tvec = range(0, 4π, length = 500)
    seriestype := :path
    color := "#191919"
    markersize := 1
    seriesalpha := 1
    (sin.(tvec), cos.(tvec))
  end

  return Data[:,1], Data[:,2]
end

function magnitude_to_radius(magnitude::Real; maxmag=8)
  0.15 * 1.4^(maxmag - magnitude)^1.025
end

function magnitude_to_alpha(magnitude::Real; maxmag=8)
  0.75 * magnitude_to_radius(magnitude; maxmag)
end

"""
    cartesian_projection(hcoords::HorizonCoordinates) -> Tuple{Float64,Float64,Float64}

Project [`HorizonCoordinates`](@ref) to the Cartesian coordinate system.
"""
function cartesian_projection(hcoords::HorizonCoordinates)
  (; h, Az) = hcoords
  x = cosd(h)sind(Az)
  y = cosd(h)cosd(Az)
  z = sind(h)
  return (x,y,z)
end

"""
    cartesian_projection(hcoords::HorizonCoordinates) -> Tuple{Float64,Float64}

Project [`HorizonCoordinates`](@ref) to the 2-dimensional Cartesian coordinate system using the stereographic projection.
"""
function stereographic_projection(hcoords::HorizonCoordinates)
  x,y,z = cartesian_projection(hcoords)

  x = x / (z + 1)
  y = y / (z + 1)

  # invert East/West, normalize to [-1, 1]
  x = (1 - x) - 1

  return (x,y)
end