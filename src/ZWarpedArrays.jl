module ZWarpedArrays

using Images, AxisArrays, ImageTransformations, Interpolations, CoordinateTransformations, CachedSeries

import CachedSeries: update_cache!, cache, cache_idxs
import Base: size, getindex, setindex!, show

export ZWarpedArray, warp_and_resample

const Array34{T} = Union{AbstractArray{T,3}, AbstractArray{T,4}}

include("util.jl")
include("zwarpedarray.jl")

end # module
