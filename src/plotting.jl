"""
    Star

Represent a star object and its data (coordinate and magnitude).
"""
struct Star{C<:Union{EquatorialCoordinates,HorizonCoordinates}}
  coordinates::C
  magnitude::Float64
end

struct MagnitudeEffect
  min::Float64
  factor::Float64
  exp::Float64
end

function magnitude_effect(value::Float64, effect::MagnitudeEffect; minvalue=2, maxvalue=8)
  (; min, factor, exp) = effect
  min + factor * (1 - (value + minvalue)/(maxvalue + minvalue))^exp
end

function plot_starmap(stars::Array{Star{EquatorialCoordinates}},
                      local_civilian_date::ZonedDateTime, 
                      latlong::LatLng;
                      projection=stereographic_projection,
                      sizeeffect=MagnitudeEffect(0.5,3,4),
                      alphaeffect=MagnitudeEffect(0,5,4),
                      kwargs...)
  stars = [Star(equatorial_to_horizon(star.coordinates, local_civilian_date, latlong), star.magnitude) for star in stars]
  filter!(s -> s.coordinates.h >= 0, stars)
  plot_starmap(
    stars;
    projection=projection,
    sizeeffect=sizeeffect,
    alphaeffect=alphaeffect,
    kwargs...)
end

function plot_starmap(stars::Array{Star{HorizonCoordinates}};
                      projection=stereographic_projection,
                      sizeeffect=MagnitudeEffect(0.5,3,4),
                      alphaeffect=MagnitudeEffect(0,5,4),
                      kwargs...)
  Projection = Matrix{Float64}(undef, length(stars), 2)

  [Projection[i,:] = projection(star.coordinates) for (i,star) in enumerate(stars)]

  scatter(
    Projection[:,1],
    Projection[:,2];
    color="#fff",
    background_color="#222",
    aspect_ratio=:equal,
    alpha=[magnitude_effect(star.magnitude, alphaeffect) for star in stars],
    markersize=[magnitude_effect(star.magnitude, sizeeffect) for star in stars],
    grid=false,
    showaxis=false,
    legend=false,
    kwargs...
  )

  # map outline
  tvec = range(0, 4π, length = 500)
  plot!(sin.(tvec), cos.(tvec), color="#191919")
end