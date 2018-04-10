mutable struct ZWarpedArray{TO,TI,N} <: CachedSeries2D{TO,TI,N}
    parent::AbstractArray{TI,N}
    tfms::Vector{CoordinateTransformations.Transformation}
    cached::Array{TO,2}
    cache_idxs::Tuple
    correct_bias::Bool
    sqrt_tfm::Bool
end

cache(A::ZWarpedArray) = A.cached
cache_idxs(A::ZWarpedArray) = A.cache_idxs

function ZWarpedArray(img::Array34{T}, tfms, out_type=Float64; correct_bias=true, sqrt_tfm=false) where {T}
    if size(img,3) !== length(tfms)
        error("Input image size in the Z-slice dimension (3) does not match the number of transforms provided")
    end
    if sqrt_tfm && !correct_bias
        warn("Square root transformation will yield incorrect results if bias was not subtracted first")
    end
    za = ZWarpedArray{out_type, T, ndims(img)}(img, tfms, zeros(out_type, size(img)[1:2]...), (ones(ndims(img)-2)...), correct_bias, sqrt_tfm)
    update_cache!(za, (ones(Int, ndims(img)-2)...))
    return za
end

function update_cache!(A::ZWarpedArray{TO, TI, N}, inds::NTuple{N2, Int}) where {TO, TI, N, N2}
    pslice = view(A.parent, :, :, inds...)
    tfm = A.tfms[inds[1]] #get transform for this slice
    if A.correct_bias && A.sqrt_tfm
        print("cor bias + sqrt\n")
        pslice = sqrt.(Float64.(correctbias.(pslice)))
    elseif A.correct_bias
        pslice = Float64.(correctbias.(pslice))
    elseif A.sqrt_tfm
        pslice = sqrt.(Float64.(pslice))
    end
    A.cached = warp_and_resample(pslice[:,:], tfm)
    A.cache_idxs = inds
end

size(A::ZWarpedArray) = size(A.parent)
show(io::IO, A::ZWarpedArray{TO}) where {TO} = print(io, "ZWarpedArray of size $(size(A)) mapped to element type $TO\n")
show(io::IO, ::MIME"text/plain", A::ZWarpedArray{TO}) where {TO} = show(io, A)

ZWarpedArray(img::ImageMeta, tfms, out_type=Float64; kwargs...) = ImageMeta(ZWarpedArray(data(img), tfms, out_type; kwargs...), properties(img))
ZWarpedArray(img::AxisArray, tfms, out_type=Float64; kwargs...) = match_axisspacing(ZWarpedArray(data(img),tfms,out_type; kwargs...), img)
