using Test
using CelestialCalc

@testset "Angle and Time conversions" begin

  @testset "DMS/HMS to decimal degree" begin
    @test dms_to_decimal(DMS(24, 13, 18)) ≈ 24.221667
    @test hms_to_decimal(HMS(24, 13, 18)) ≈ 24.221667
  end

end