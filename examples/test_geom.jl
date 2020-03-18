##
using Libdl
using libsharp2_jll
using LibSharp
using Healpix

##

nside = 4
lmax = 4
geom_info = make_weighted_healpix_geom_info(
    nside, 1)
alm_info = make_triangular_alm_info(lmax, lmax, 1)

npix = map_size(geom_info)
nalms = alm_count(alm_info)

##
alms = ones(ComplexF64, (nalms))
maps = 2.0  .* ones((npix))

GC.@preserve alms maps ccall(
    (:sharp_execute, libsharp2),
    Cvoid,
    (
        Cint, Cint, Ptr{Cvoid}, Ptr{Cvoid}, 
        Ptr{Cvoid}, Ptr{Cvoid}, Cint,
        Ref{Cdouble}, Ref{Culonglong}
    ),
    0, 0, [pointer(alms)], [pointer(maps)],
    geom_info.ptr, alm_info.ptr, LibSharp.SHARP_DP,
    Ptr{Cdouble}(C_NULL), Ptr{Culonglong}(C_NULL)
)

println(alms)
##