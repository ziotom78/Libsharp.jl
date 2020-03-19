module LibSharp

using Libdl
using libsharp2_jll

export AlmInfo, make_alm_info, alm_index, alm_count
export make_triangular_alm_info

export GeomInfo, make_weighted_healpix_geom_info, map_size
export sharp_execute!

mutable struct AlmInfo
    ptr::Ptr{Cvoid}

    AlmInfo(ptr::Ptr{Cvoid}) = finalizer(destroy_alm_info, new(ptr))
end

function make_alm_info(lmax::Integer, mmax::Integer, stride::Integer, 
                       mstart::AbstractArray{T}) where T <: Integer
    alm_info_ptr = Ref{Ptr{Cvoid}}()
    mstart_cint = [Cint(x) for x in mstart]
    ccall(
        (:sharp_make_alm_info, libsharp2),
        Cvoid,
        (Cint, Cint, Cint, Ref{Cint}, Ref{Ptr{Cvoid}}),
        lmax, mmax, stride, mstart_cint, alm_info_ptr,
    )

    AlmInfo(alm_info_ptr[])
end

"""
Initialises an a_lm data structure according to the scheme 
used by Healpix_cxx.
 
### Returns
 AlmInfo object
"""
function make_triangular_alm_info(lmax::Integer, mmax::Integer, 
                                  stride::Integer)

    alm_info_ptr = Ref{Ptr{Cvoid}}()
    ccall(
        (:sharp_make_triangular_alm_info, libsharp2),
        Cvoid,
        (Cint, Cint, Cint, Ref{Ptr{Cvoid}}),
        lmax, mmax, stride, alm_info_ptr,
    )

    AlmInfo(alm_info_ptr[])
end

function destroy_alm_info(info::AlmInfo)
    ptr = info.ptr

    if ptr != C_NULL
        info.ptr = C_NULL
        ccall(
            (:sharp_destroy_alm_info, libsharp2),
            Cvoid,
            (Ptr{Cvoid},),
            ptr,
        )
    end
end

function alm_index(alm::AlmInfo, l::Integer, mi::Integer)
    ccall(
        (:sharp_alm_index, libsharp2),
        Cptrdiff_t,
        (Ptr{Cvoid}, Cint, Cint),
        alm.ptr, l, mi,
    )
end

alm_count(alm::AlmInfo) = ccall(
    (:sharp_alm_count, libsharp2),
    Cptrdiff_t,
    (Ptr{Cvoid},),
    alm.ptr,
)


mutable struct GeomInfo
    ptr::Ptr{Cvoid}

    GeomInfo(ptr::Ptr{Cvoid}) = finalizer(destroy_geom_info, new(ptr))
end

function destroy_geom_info(info::GeomInfo)
    ptr = info.ptr

    if ptr != C_NULL
        info.ptr = C_NULL
        ccall(
            (:sharp_destroy_geom_info, libsharp2),
            Cvoid,
            (Ptr{Cvoid},),
            ptr,
        )
    end
end

function make_weighted_healpix_geom_info(
        nside::Integer, stride::Integer, weight::AbstractArray{T}
    ) where T

    geom_info_ptr = Ref{Ptr{Cvoid}}()

    # check for right number of ring weights
    nrings = 4 * nside - 1
    @assert length(weight) == nrings

    weight_cdouble = [Cdouble(x) for x in weight]  
    ccall(
        (:sharp_make_weighted_healpix_geom_info, libsharp2),
        Cvoid,
        (Cint, Cint, Ref{Cdouble}, Ref{Ptr{Cvoid}}),
        nside, stride, weight_cdouble, geom_info_ptr,
    )
    GeomInfo(geom_info_ptr[])
end

function make_weighted_healpix_geom_info(nside::Integer, stride::Integer)
    geom_info_ptr = Ref{Ptr{Cvoid}}()
    ccall(
        (:sharp_make_weighted_healpix_geom_info, libsharp2),
        Cvoid,
        (Cint, Cint, Ref{Cdouble}, Ref{Ptr{Cvoid}}),
        nside, stride, Ptr{Cdouble}(C_NULL), geom_info_ptr,
    )
    # passes NULL for ring weights

    GeomInfo(geom_info_ptr[])
end

"""
Counts the number of grid points needed for (the local part of) a 
map described by geometry info.
"""
map_size(geom_info::GeomInfo) = ccall(
    (:sharp_map_size, libsharp2),
    Cptrdiff_t,
    (Ptr{Cvoid},),
    geom_info.ptr
)


"""
SHARP job types.
"""
const SHARP_YtW = Cint(0)               # analysis
const SHARP_MAP2ALM = SHARP_YtW         # analysis
const SHARP_Y = Cint(1)                 # synthesis
const SHARP_ALM2MAP = Cint(SHARP_Y)     # synthesis
const SHARP_Yt = Cint(2)                # adjoint synthesis
const SHARP_WY = Cint(3)                # adjoint analysis
const SHARP_ALM2MAP_DERIV1 = Cint(4)    # synthesis of first derivatives

"""
SHARP job flags.
"""
# map and a_lm are in double precision
const SHARP_DP = Cint(1<<4)     
# results are added to the output arrays, instead of overwriting them
const SHARP_ADD = Cint(1<<5)    
const SHARP_NO_FFT = Cint(1<<7)



"""
Performs a libsharp2 SHT job.

This sets `double *time`, `unsigned long long *opcnt` to C_NULL.
"""
function sharp_execute!(jobtype::Integer, spin::Integer, 
                        alms::Array{Array{Complex{T},1},1}, 
                        maps::Array{Array{T,1},1}, 
                        geom_info::GeomInfo, alm_info::AlmInfo, 
                        flags::Integer) where T <: AbstractFloat

    GC.@preserve alms maps ccall(
        (:sharp_execute, libsharp2),
        Cvoid,
        (
            Cint, Cint, Ptr{Cvoid}, Ptr{Cvoid}, 
            Ptr{Cvoid}, Ptr{Cvoid}, Cint,
            Ref{Cdouble}, Ref{Culonglong}
        ),
        jobtype, spin, 
        [pointer(alm) for alm in alms], 
        [pointer(map) for map in maps],
        geom_info.ptr, alm_info.ptr, flags,
        Ptr{Cdouble}(C_NULL), Ptr{Culonglong}(C_NULL)
    )
end



end # module
