_index_extrap(etp, inds) = etp(inds...)
function warp_and_resample(img, tfm; fillval=0.0)
    inds0 = axes(img)
    img = warp(img, tfm)
    itp = interpolate(img, BSpline(Interpolations.Linear()))
    etp = extrapolate(itp, fillval)
    return _index_extrap(etp, inds0) #Function barrier improves performance
end
