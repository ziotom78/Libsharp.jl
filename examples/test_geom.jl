##
# using Libdl
# using libsharp2_jll
using LibSharp
using Healpix
##

nside = 4
lmax = 2
npix = 12*nside*nside
n_alm = Int64( ((lmax+1)*(lmax+2))/2 )
geom_info = make_weighted_healpix_geom_info(nside, 1)
alm_info = make_triangular_alm_info(lmax, lmax, 1)

##
# maps = Array{Cdouble,1}[rand(Cdouble, (npix))]
# alms = Array{ComplexF64,1}[zeros(ComplexF64, (n_alm))]

map0 = ones(Cdouble, (npix))
refMap = [Ref(map0, 1)]
alm0 = zeros(ComplexF64, (n_alm))
refAlm = [Ref(alm0, 1)]
##
LibSharp.sharp_execute(
    LibSharp.SHARP_MAP2ALM, 0, 
    refAlm, 
    refMap, 
    geom_info, alm_info, 
    LibSharp.SHARP_DP)
##
println(alm0)
##