mutable struct ZWarpedArray{TO,TI,N,NC,AA<:AbstractArray} <: AbstractCachedArray{TO,TI,N,NC,AA}
    parent::AA
    tfms::Vector{CoordinateTransformations.Transformation}
    cached::Array{TO,NC}
    current_I::Tuple
    correct_bias::Bool
    sqrt_tfm::Bool
end

cache(A::ZWarpedArray) = A.cached
current_I(A::ZWarpedArray) = A.current_I
set_I!(A::ZWarpedArray, inds) = A.current_I = inds

function ZWarpedArray(img::AbstractArray{T, N}, tfms, out_type=Float64, nd_cache::Int=2; correct_bias=true, sqrt_tfm=false) where {T, N}
    if !(2 < ndims(img) < 5)
        error("Only 3D and 4D images are supported")
    end
    if size(img,3) !== length(tfms)
        error("Input image size in the Z-slice dimension (3) does not match the number of transforms provided")
    end
    if nd_cache < 2 || nd_cache > 3
        error("nd_cache must be 2 or 3")
    end
    if sqrt_tfm && !correct_bias
        warn("Square root transformation will yield incorrect results if bias was not subtracted first")
    end
    if correct_bias && !in(T, (Normed{UInt16, 16}, UInt16))
        warn("Unable to guess the camera bias value for element type $T.  Defaulting to 100/(2^16)")
    end
    cache_rngs = axes(img)[nd_cache+1:ndims(img)]
    ci = map(first, cache_rngs)
    cached = similar(view(img, axes(img)[1:nd_cache]..., ci...), out_type)
    za = ZWarpedArray{out_type, T, ndims(img), nd_cache, typeof(img)}(img, tfms, cached, (ci...,), correct_bias, sqrt_tfm)
    update_cache!(za, (ci...,))
    return za
end

function _update_cache!(c::AbstractArray{T,2}, parent, tfm::CoordinateTransformations.Transformation, pp::Function) where {T}
    c .= pp.(warp_and_resample(parent, tfm)) #TODO: do this in-place
    return nothing
end

function _update_cache!(c::AbstractArray{T,3}, parent, tfms, pp::Function) where {T}
    for (i,v) in enumerate(axes(c,3))
        _update_cache!(view(c, :, :, v), view(parent, :, :, v), tfms[i], pp)
    end
    return nothing
end

function biasval(t::Type)
    native = UInt16(100)
    return ifelse(t==UInt16, native, reinterpret(Normed{UInt16, 16}, native))
end

function update_cache!(A::ZWarpedArray{TO,TI,N,NC,AA}, inds::NTuple{N2,Int}) where {TO,TI,N,NC,AA,N2}
    pslice = view(parent(A), cached_axes(A)..., inds...) #TODO: may be faster to use copy instead of view here
    pp = identity
    #note: the max statements below only seem necessary due to the way fixed point numbers are converted,
    #see Interpolations #118
    if A.correct_bias && A.sqrt_tfm
        pp = x-> sqrt(Float64(max(0, x-biasval(TI))))
    elseif A.correct_bias
        pp = x-> Float64(max(0, x- biasval(TI)))
    elseif A.sqrt_tfm
        pp = x-> sqrt(Float64(x))
    end
    if length(cached_axes(A)) == 2
        tfmidx = findfirst(isequal(first(inds)), axes(A,3))
        _update_cache!(cache(A), pslice, A.tfms[tfmidx], pp)
    else
        _update_cache!(cache(A), pslice, A.tfms, pp)
    end
    set_I!(A, inds)
    return nothing
end

show(io::IO, A::ZWarpedArray{TO}) where {TO} = print(io, "ZWarpedArray of size $(size(A)) mapped to element type $TO\n")
show(io::IO, ::MIME"text/plain", A::ZWarpedArray{TO}) where {TO} = show(io, A)

ZWarpedArray(img::ImageMeta, tfms, out_type=Float64; kwargs...) = ImageMeta(ZWarpedArray(data(img), tfms, out_type; kwargs...), properties(img))
ZWarpedArray(img::AxisArray, tfms, out_type=Float64; kwargs...) = match_axisspacing(ZWarpedArray(data(img),tfms,out_type; kwargs...), img)
