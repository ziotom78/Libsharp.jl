module LibSharp

using Libdl
using libsharp2_jll

export AlmInfo, make_alm_info, alm_index, alm_count

mutable struct AlmInfo
    ptr::Ptr{Cvoid}

    AlmInfo(ptr::Ptr{Cvoid}) = finalizer(destroy_alm_info, new(ptr))
end

function make_alm_info(lmax::Integer, mmax::Integer, stride::Integer, mstart::AbstractArray{T}) where T <: Integer
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

end # module
