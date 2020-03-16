using LibSharp
using Test

@testset "LibSharp.jl" begin
    alm = make_alm_info(10, 10, 1, 0:10)
    @test alm_count(alm) == 66

    triangular_alm = make_triangular_alm_info(10, 10, 1)
    @test alm_count(triangular_alm) == 66

    println(alm_index(alm, 1, 1))
end
