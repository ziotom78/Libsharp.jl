using Libsharp
using Test

## tests relating to the storage of a_lm coefficients
@testset "alm" begin
    # test the finalizer of the AlmInfo
    triangular_alm = make_triangular_alm_info(10, 10, 1)
    @test triangular_alm.ptr != C_NULL
    Libsharp.destroy_alm_info(triangular_alm)
    @test triangular_alm.ptr == C_NULL

    # test the 0-based alm index computation
    triangular_alm = make_triangular_alm_info(10, 10, 1)
    @test alm_index(triangular_alm, 5, 4) == 39
    alm = make_alm_info(10, 10, 1, 0:10)
    @test alm_index(alm, 5, 4) == 9
    general_alm = make_general_alm_info(3, 4, 1, 0:3, [0, 3, 5, 6])
    @test alm_index(general_alm, 3, 2) == 8
    alm = make_mmajor_complex_alm_info(6, 1, nothing)
    @test alm_index(alm, 5, 4) == 23

    # test total counts
    alm = make_alm_info(10, 10, 1, 0:10)
    @test alm_count(alm) == 66
    triangular_alm = make_triangular_alm_info(10, 10, 1)
    @test alm_count(triangular_alm) == 66
    general_alm = make_general_alm_info(3, 4, 1, 0:3, [0, 3, 5, 6])
    @test alm_count(general_alm) == 10
    alm = make_mmajor_complex_alm_info(6, 1, nothing)
    @test alm_count(alm) == 28
end

## tests relating to pixelization properties
@testset "geom" begin
    # test the finalizer of the AlmInfo
    geom_info = make_healpix_geom_info(16, 1)
    @test geom_info.ptr != C_NULL
    Libsharp.destroy_geom_info(geom_info)
    @test geom_info.ptr == C_NULL

    # test the total number of pixels
    geom_info = make_healpix_geom_info(16, 1)
    @test map_size(geom_info) == 3072
    geom_info = make_weighted_healpix_geom_info(
        16, 1, ones(16 * 4 - 1))
    @test map_size(geom_info) == 3072

    #test the number of pixels in a subset
    geom_info = make_subset_healpix_geom_info(8, 1, 6, [14, 18, 9, 23, 4, 28])
    @test map_size(geom) == 160

    #and finalizer
    @test geom_info.ptr != C_NULL
    Libsharp.destroy_geom_info(geom_info)
    @test geom_info.ptr == C_NULL
end

## tests relating to spherical harmonic transform map2alm
@testset "map2alm" begin
    # set up
    nside = 4
    lmax = 4
    geom_info = make_healpix_geom_info(nside, 1)
    alm_info = make_triangular_alm_info(lmax, lmax, 1)
    npix = map_size(geom_info)
    nalms = alm_count(alm_info)

    ## spin 0 test
    alms = [ones(ComplexF64, nalms)]
    maps = [2 .* ones(npix)]
    sharp_execute!(
        SHARP_MAP2ALM, 0, alms, maps,
        geom_info, alm_info, SHARP_DP
    )
    test_alm_spin0 = [
        7.08981540e+00+0.00000000e+00im,  6.26606889e-17+0.00000000e+00im,
        -4.64452418e-02+0.00000000e+00im, -1.43573675e-16+0.00000000e+00im,
        -1.10275269e-01+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
        0.00000000e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
        0.00000000e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
        0.00000000e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
        0.00000000e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
        -7.87873039e-04-9.64866195e-20im]
    @test isapprox(alms[1] , test_alm_spin0)

    # spin 2 test
    alms = [zeros(ComplexF64, nalms), zeros(ComplexF64, nalms)]
    maps = [2.0 .* ones(npix), 2.0 .* ones(npix)]
    sharp_execute!(
        SHARP_MAP2ALM, 2, alms, maps,
        geom_info, alm_info, SHARP_DP
    )
    test_alm_spin2 = [
        0.00000000e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
        -6.49104757e+00+0.00000000e+00im, -1.31064234e-16+0.00000000e+00im,
        -2.27889895e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
         0.00000000e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
         0.00000000e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
         0.00000000e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
         0.00000000e+00+0.00000000e+00im,  0.00000000e+00+0.00000000e+00im,
         2.36716190e-02+2.89893725e-18im]
    @test isapprox(alms[1] , test_alm_spin2)
    @test isapprox(alms[2] , test_alm_spin2)

end

## tests relating to spherical harmonic transform alm2map
@testset "alm2map" begin
    nside = 2
    lmax = 2
    geom_info = make_healpix_geom_info(nside, 1)
    alm_info = make_triangular_alm_info(lmax, lmax, 1)
    npix = map_size(geom_info)
    nalms = alm_count(alm_info)

    # test the inverse transform, SHARP_ALM2MAP, spin 0
    alms = [2 .* ones(ComplexF64, nalms)]
    maps = [zeros(npix)]
    sharp_execute!(
        SHARP_ALM2MAP, 0, alms, maps,
        geom_info, alm_info, SHARP_DP
    )
    test_map_spin0 = [
        1.22822792,  3.61032581,  3.61032581,  1.22822792, -0.33740788,
       -0.16286106,  1.80075965,  4.40319186,  4.40319186,  1.80075965,
       -0.16286106, -0.33740788, -0.4312723 , -1.13862492, -0.90401688,
        2.07742993,  4.11691608,  2.07742993, -0.90401688, -1.13862492,
       -0.25082501, -1.68800153, -0.63028243,  2.30273478,  2.30273478,
       -0.63028243, -1.68800153, -0.25082501,  0.859566  , -0.41667555,
       -1.5554869 ,  0.05254053,  1.52313774,  0.05254053, -1.5554869 ,
       -0.41667555,  1.19694074, -0.29055765, -0.67742383,  0.26296318,
        0.26296318, -0.67742383, -0.29055765,  1.19694074,  1.03769816,
        0.21777049,  0.21777049,  1.03769816]
    @test isapprox(maps[1] , test_map_spin0)

    # test spin 2
    alms = [2 .* ones(ComplexF64, nalms), 2 .* ones(ComplexF64, nalms)]
    maps = [zeros(npix), zeros(npix)]
    sharp_execute!(
        SHARP_ALM2MAP, 2, alms, maps,
        geom_info, alm_info, SHARP_DP
    )
    test_map_spin2_E = [
        -1.9631492 ,  1.00333301, -0.59650858,  1.06275217, -2.6071711 ,
        -1.4882688 ,  0.1809384 , -0.25943678, -0.72916617,  0.72899969,
        1.43862464, -0.69806834, -1.78405186, -2.22862401, -1.17525562,
        -0.82688372, -0.99110781,  0.01416045,  1.20357653,  0.29450851,
        -1.70135994, -1.49205262, -1.49205262, -1.70135994, -0.73579893,
        0.83901787,  0.83901787, -0.73579893, -0.99110781, -0.82688372,
        -1.17525562, -2.22862401, -1.78405186,  0.29450851,  1.20357653,
        0.01416045, -0.25943678,  0.1809384 , -1.4882688 , -2.6071711 ,
        -0.69806834,  1.43862464,  0.72899969, -0.72916617,  1.00333301,
        -1.9631492 ,  1.06275217, -0.59650858]
    @test isapprox(maps[1] , test_map_spin2_E)

    test_map_spin2_B = [
        1.06275217, -0.59650858,  1.00333301, -1.9631492 , -0.69806834,
         1.43862464,  0.72899969, -0.72916617, -0.25943678,  0.1809384 ,
        -1.4882688 , -2.6071711 , -1.78405186,  0.29450851,  1.20357653,
         0.01416045, -0.99110781, -0.82688372, -1.17525562, -2.22862401,
        -0.73579893,  0.83901787,  0.83901787, -0.73579893, -1.70135994,
        -1.49205262, -1.49205262, -1.70135994, -0.99110781,  0.01416045,
         1.20357653,  0.29450851, -1.78405186, -2.22862401, -1.17525562,
        -0.82688372, -0.72916617,  0.72899969,  1.43862464, -0.69806834,
        -2.6071711 , -1.4882688 ,  0.1809384 , -0.25943678, -0.59650858,
         1.06275217, -1.9631492 ,  1.00333301]
    @test isapprox(maps[2] , test_map_spin2_B)
end

@testset "Other stuff" begin
    arch = architecture()
    @test typeof(arch) == String
    @test arch != ""

    vector_length = veclen()
    @test typeof(vector_length) == Int
    @test vector_length ≥ 1
end
