module ZWarpedArrays

using Images, AxisArrays, ImageTransformations, Interpolations, CoordinateTransformations
const axes = Base.axes #for name conflict with AxisArrays

using Unitful #just for match_axisspacing

using CachedArrays
import CachedArrays: AbstractCachedArray,
                        update_cache!,
                        parent,
                        cache,
                        current_I,
                        set_I!,
                        cached_axes,
                        noncached_axes,
                        axisspacing,
                        match_axisspacing
import Base: show

export ZWarpedArray, warp_and_resample

include("util.jl")
include("zwarpedarray.jl")

end # module
