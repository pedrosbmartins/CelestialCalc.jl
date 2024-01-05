using Documenter, CelestialCalc

makedocs(
  sitename="CelestialCalc.jl",
  pages=[
    "Home" => "index.md",
    "angles.md",
    "coordinate_systems.md",
    "data.md",
    "plotting.md",
    "time.md",
  ]
)