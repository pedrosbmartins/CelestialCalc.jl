using Test
using CelestialCalc

@testset "Angle and Time conversions" begin

  @testset "DMS/HMS to decimal" begin
    @test dms_to_decimal(DMS(24,13,18)) ≈ 24.221667
    @test hms_to_decimal(HMS(24,13,18)) ≈ 24.221667

    @test dms_to_decimal(DMS(10,25,11)) ≈ 10.4197223
    @test hms_to_decimal(HMS(10,25,11)) ≈ 10.4197223

    @test dms_to_decimal(DMS(13,4,10)) ≈ 13.0694445
    @test hms_to_decimal(HMS(13,4,10)) ≈ 13.0694445

    @test dms_to_decimal(DMS(300,20,0)) ≈ 300.333333
  end

  @testset "decimal to DMS/HMS" begin
    @test decimal_to_dms(24.221667) == DMS(24,13,18)
    @test decimal_to_hms(24.221667) == HMS(24,13,18)

    @test decimal_to_dms(20.352) == DMS(20,21,7.2)
    @test decimal_to_hms(20.352) == HMS(20,21,7.2)

    @test decimal_to_dms(10.2958) == DMS(10,17,44.88)
    @test decimal_to_hms(10.2958) == HMS(10,17,44.88)

    @test decimal_to_dms(-0.508333) == DMS(0,30,30,true)
  end

end