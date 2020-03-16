##
# using Libdl
# using libsharp2_jll
using LibSharp
using Healpix
##
# alm = make_triangular_alm_info(10, 10, 1)
nside = 4
lmax = 4
npix = 12*nside*nside
n_alm = Int64( ((lmax+1)*(lmax+2))/2 )
geom_info = make_weighted_healpix_geom_info(nside, 1)
alm_info = make_triangular_alm_info(lmax, lmax, 1)

##
map_size(geom_info)

##
maps = Array{Float64,1}[rand((npix))]
alms = Array{ComplexF64,1}[zeros(ComplexF64, (n_alm))]

##
LibSharp.sharp_execute(
    LibSharp.SHARP_MAP2ALM, 0, 
    alms, 
    maps, 
    geom_info, alm_info, 
    LibSharp.SHARP_DP)
##
print(alms)
##