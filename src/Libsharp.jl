module Libsharp

using Libdl
using libsharp2_jll

export AlmInfo, make_alm_info, alm_index, alm_count
export make_triangular_alm_info, make_general_alm_info

export GeomInfo, map_size
export make_weighted_healpix_geom_info, make_healpix_geom_info
export sharp_execute!

export SHARP_YtW, SHARP_MAP2ALM, SHARP_Y, SHARP_ALM2MAP
export SHARP_Yt, SHARP_WY, SHARP_ALM2MAP_DERIV1
export SHARP_DP, SHARP_ADD, SHARP_NO_FFT

export architecture, veclen

"""
    architecture()

Returns a string describing the kind of architecture used when
compiling the libsharp C library

"""
function architecture()
    str_ptr = ccall(
        (:sharp_architecture, libsharp2),
        Ptr{UInt8},
        (),
    )

    unsafe_string(str_ptr)
end

"""
    veclen()

Return the number of elements processed simultaneously by libsharp in
one operation. This depends on the architecture (e.g., AVX, SSE2…)
used to build the library.

"""
function veclen()
    ccall(
        (:sharp_veclen, libsharp2),
        Int,
        (),
    )
end

"""
    AlmInfo

Stores a C pointer to alm format information.

# Fields
- `ptr::Ptr{Cvoid}`: pointer to the C structure
"""
mutable struct AlmInfo
    ptr::Ptr{Cvoid}

    AlmInfo(ptr::Ptr{Cvoid}) = finalizer(destroy_alm_info, new(ptr))
end


"""
    make_alm_info(lmax::Integer, mmax::Integer, stride::Integer,
        mstart::AbstractArray{T}) where T <: Integer

Initialises a general a_lm data structure.

# Arguments
- `lmax::Integer`: maximum spherical harmonic ℓ
- `mmax::Integer`: maximum spherical harmonic m
- `stride::Integer`: the stride between consecutive pixels in the ring
- `mstart::AbstractArray{T}`: index of the coefficient with the quantum
    numbers 0, m. Must have mmax+1 entries.

# Returns
- AlmInfo object
"""
function make_alm_info(lmax::Integer, mmax::Integer, stride::Integer,
                       mstart::AbstractArray{T}) where T <: Integer
    alm_info_ptr = Ref{Ptr{Cvoid}}()
    mstart_cptrdiff = [Cptrdiff_t(x) for x in mstart]
    ccall(
        (:sharp_make_alm_info, libsharp2),
        Cvoid,
        (Cint, Cint, Cint, Ref{Cptrdiff_t}, Ref{Ptr{Cvoid}}),
        lmax, mmax, stride, mstart_cptrdiff, alm_info_ptr,
    )

    AlmInfo(alm_info_ptr[])
end


"""
    make_genral_alm_info(
        lmax::Integer, mmax::Integer, stride::Integer, mval::AbstractArray{T}, mstart::AbstractArray{T}
        ) where T <: Integer

Initialises a general a_lm data structure according to the following parameter.
It can be used to construct an `AlmInfo` object for a subset of an `Alm` set.

# Arguments
- `lmax::Integer`: maximum spherical harmonic ℓ
- `nm::Integer`: number of different m values
- `stride::Integer`: the stride between consecutive ℓ's
- `mval::AbstractArray{T}`: array with `nm` entries containing the individual m values
- `mstart::AbstractArray{T}`: array with `nm` entries containing the (hypothetical)
    indices {i} of the coefficients with the quantum numbers ℓ=0, m=mval[i]

# Returns
- `AlmInfo` object
"""
function make_general_alm_info(
    lmax::Integer,
    nm::Integer,
    stride::Integer, #generally = 1
    mval::AbstractArray{T},
    mstart::AbstractArray{T}
    ) where T <: Integer

    alm_info_ptr = Ref{Ptr{Cvoid}}()
    mval_cint = [Cint(x) for x in mval]
    mstart_cptrdiff = [Cptrdiff_t(x) for x in mstart]

    ccall(
        (:sharp_make_general_alm_info, libsharp2),
        Cvoid,
        (Cint, Cint, Cint, Ref{Cint}, Ref{Cptrdiff_t}, Cint, Ref{Ptr{Cvoid}}),
        lmax, nm, stride, mval_cint, mstart_cptrdiff, 0, alm_info_ptr,
    )

    AlmInfo(alm_info_ptr[])
end

"""
    make_triangular_alm_info(lmax::Integer, mmax::Integer, stride::Integer)

Initialises an a_lm data structure according to the scheme
used by Healpix_cxx.

# Arguments
- `lmax::Integer`: maximum spherical harmonic ℓ
- `mmax::Integer`: maximum spherical harmonic m
- `stride::Integer`: the stride between consecutive ℓ's

# Returns
- `AlmInfo` object
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

"""
    destroy_alm_info(info::AlmInfo)

Deallocate the C object corresponding to a libsharp alm info.
"""
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

"""
    alm_index(alm::AlmInfo, l::Integer, mi::Integer)

Compute the 0-based index of the l,m harmonic.
"""
function alm_index(alm::AlmInfo, l::Integer, mi::Integer)
    ccall(
        (:sharp_alm_index, libsharp2),
        Cptrdiff_t,
        (Ptr{Cvoid}, Cint, Cint),
        alm.ptr, l, mi,
    )
end

"""
    alm_count(alm::AlmInfo)

Compute the total number of spherical harmonic coefficients in the AlmInfo.
"""
alm_count(alm::AlmInfo) = ccall(
    (:sharp_alm_count, libsharp2),
    Cptrdiff_t,
    (Ptr{Cvoid},),
    alm.ptr,
)

"""
    GeomInfo

Stores a C pointer to geometry information like ring sizes.

# Fields
- `ptr::Ptr{Cvoid}`: pointer to the C structure
"""
mutable struct GeomInfo
    ptr::Ptr{Cvoid}

    GeomInfo(ptr::Ptr{Cvoid}) = finalizer(destroy_geom_info, new(ptr))
end

"""
    destroy_geom_info(info::GeomInfo)

Deallocate the C object corresponding to a libsharp geometry info.
"""
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

"""
    make_weighted_healpix_geom_info(
        nside::Integer, stride::Integer, weight::AbstractArray{T}
        ) where T <: Real

Initialises a geometry structure corresponding to HEALPix.

# Arguments
- `nside::Integer`: HEALPix resolution parameter
- `stride::Integer`: the stride between consecutive pixels in the ring
- `weight::AbstractArray{T}`: the weight that must be multiplied to every pixel
    during a map analysis (typically the solid angle of a pixel in the ring)

# Returns
- `GeomInfo` object
"""
function make_weighted_healpix_geom_info(
        nside::Integer, stride::Integer, weight::AbstractArray{T}
    ) where T <: Real

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

"""
    make_healpix_geom_info(nside::Integer, stride::Integer)

Initialises a HEALPix geometry structure with equal pixel weights.

# Arguments
- `nside::Integer`: HEALPix resolution parameter
- `stride::Integer`: the stride between consecutive pixels in the ring

# Returns
- `GeomInfo` object
"""
function make_healpix_geom_info(nside::Integer, stride::Integer)
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
    map_size(geom_info::GeomInfo)

Counts the number of grid points needed for (the local part of) a
map described by geometry info.

# Returns
- `Cint`
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
const SHARP_DP = Cint(1<<4)   # map and a_lm are in double precision
const SHARP_ADD = Cint(1<<5)  # results are added to the output
                              # arrays, instead of overwriting them
const SHARP_NO_FFT = Cint(1<<7)


"""
    sharp_execute!(args...) where T <: AbstractFloat

Performs a libsharp2 SHT job.

For a spin 0 field, maps[1] should be the array of containing the map elements.
Similarly, for a spin 2 field, maps[1] and maps[2] contain the two spin-2
components. The alms are in a similar format, i.e. alms[1] and alms[2] are the
harmonics describing a spin-2 field.

You should specify `flags=0` for single precision and `flags=SHARP_DP` for
double precision.

# Arguments
- `jobtype::Integer`: libsharp job type
- `spin::Integer`: spin of the field
- `alms::Array{Array{Complex{T},1},1}`: alm arrays
- `maps::Array{Array{T,1},1}`: map arrays
- `geom_info::GeomInfo`: pixelisation info
- `alm_info::AlmInfo`: spherical harmonic coefficients info
- `flags::Integer`: additional flags
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
