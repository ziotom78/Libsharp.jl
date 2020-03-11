using LibSharp
using Test

@testset "LibSharp.jl" begin
    alm = make_alm_info(10, 10, 1, 0:10)
    @assert alm_count(alm) == 66
    println(alm_index(alm, 1, 1))
end
