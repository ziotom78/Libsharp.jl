module LibSharp

using Libdl
using libsharp2_jll

export AlmInfo, make_alm_info, alm_index, alm_count
export make_triangular_alm_info

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

# ADD THIS FOR HEALPIX
# sharp_make_weighted_healpix_geom_info(cs->n_eq,1,NULL,&geom_info);

end # module
