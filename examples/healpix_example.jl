using LibSharp
using Healpix

## set up geometry and alms
nside = 4
lmax, mmax = 4, 4
geom_info = make_healpix_geom_info(nside, 1)  # unweighted healpix map
alm_info = make_triangular_alm_info(lmax, mmax, 1)
npix = map_size(geom_info)
nalms = alm_count(alm_info)

## spin 0 example for map2alm. for alm2map, pass SHARP_ALM2MAP to sharp_execute!
alms = [ones(ComplexF64, nalms)]
maps = [2 .* ones(npix)]
sharp_execute!(
    SHARP_MAP2ALM, 0, alms, maps,
    geom_info, alm_info, SHARP_DP
)
println("\nmap with all pixels=2 map2alm spin 0 alms:\n", alms, "\n")

## spin 2 example
alms = [ones(ComplexF64, (nalms)), ones(ComplexF64, (nalms))]
maps = [2.0  .* ones((npix)), 2.0  .* ones((npix))]
sharp_execute!(
    SHARP_MAP2ALM, 2, alms, maps,
    geom_info, alm_info, SHARP_DP
)
println("\nmap with all pixels=2 map2alm spin 2 alms:\n", alms, "\n")
