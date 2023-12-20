using Test
using TimeZones

using CelestialCalc

@testset "AngleDMS" begin
  @testset "AngleDMS display" begin
    @test string(AngleDMS(24,4,18.5)) == "24°04'18.50''"
    @test string(AngleDMS(0,30,30,true)) == "-0°30'30.00''"
  end
  
  @testset "AngleDMS to decimal" begin
    @test angle_to_decimal(AngleDMS(24,13,18)) ≈ 24.221667
    @test angle_to_decimal(AngleDMS(10,25,11)) ≈ 10.4197223
    @test angle_to_decimal(AngleDMS(13,4,10,true)) ≈ -13.0694445
  end

  @testset "decimal to AngleDMS" begin
    @test decimal_to_angle(24.221667) == AngleDMS(24,13,18)
    @test decimal_to_angle(20.352) == AngleDMS(20,21,7.2)
    @test decimal_to_angle(10.2958) == AngleDMS(10,17,44.88)
    @test decimal_to_angle(-0.508333) == AngleDMS(0,30,30,true)
  end
end

@testset "Time conversions to/from decimal" begin
  @testset "Time to decimal" begin
    @test time_to_decimal(Time(10,25,11)) ≈ 10.4197223
    @test time_to_decimal(Time(13,4,10)) ≈ 13.0694445
  end
  
  @testset "decimal to Time" begin
    @test decimal_to_time(20.352) == Time(20,21,7,20)
    @test decimal_to_time(10.2958) == Time(10,17,44,88)
  end
end

@testset "Time conversions" begin
  @testset "UT to GST" begin
    @test ut_to_gst(ZonedDateTime(2010,2,7,23,30,tz"UTC")) ≈ 8.698090630099976
    @test ut_to_gst(ZonedDateTime(2014,12,13,1,tz"UTC")) ≈ 6.442866622675775
  end
end