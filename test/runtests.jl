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

@testset "Time conversions" begin
  @testset "Time to decimal" begin
    @test time_to_decimal(Time(10,25,11)) ≈ 10.4197223
    @test time_to_decimal(Time(13,4,10)) ≈ 13.0694445
  end
  
@testset "Decimal to Time" begin
    @test decimal_to_time(20.352) == Time(20,21,7,200)
    @test decimal_to_time(10.2958) == Time(10,17,44,880)
  end

  @testset "LCT to UT" begin
    @test local_to_universal_time(ZonedDateTime(2023,12,26,20,tz"UTC-3")) == ZonedDateTime(2023,12,26,23,tz"UTC")
  end

  @testset "UT to GST" begin
    @test solar_to_prime_sidereal_time(ZonedDateTime(2010,2,7,23,30,tz"UTC")) ≈ 8.698090630099976
    @test solar_to_prime_sidereal_time(ZonedDateTime(2014,12,13,1,tz"UTC")) ≈ 6.442866622675775
  end

  @testset "GST to LST" begin
    @test prime_to_local_sidereal_time(time_to_decimal(Time(2,3,41)), -40.0) ≈ 23.39472222222222
    @test prime_to_local_sidereal_time(time_to_decimal(Time(6,26,34)), -77.0) ≈ 1.3094444444444444
  end

  @testset "LCT to LST" begin
    @test local_civilian_to_sidereal_time(ZonedDateTime(2023,12,26,20,tz"UTC-3"), -42.94514) ≈ 2.4825123186
  end
end