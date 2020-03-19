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

## spin 0 example
alms = [ones(ComplexF64, (nalms))]
maps = [2.0  .* ones((npix))]

sharp_execute!(
    LibSharp.SHARP_MAP2ALM, 0, alms, maps,
    geom_info, alm_info, LibSharp.SHARP_DP
)

println(alms)

## spin 2 example
alms = [ones(ComplexF64, (nalms)), ones(ComplexF64, (nalms))]
maps = [2.0  .* ones((npix)), 2.0  .* ones((npix))]

sharp_execute!(
    LibSharp.SHARP_MAP2ALM, 2, alms, maps,
    geom_info, alm_info, LibSharp.SHARP_DP
)



