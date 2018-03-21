using ZWarpedArrays, Images, CoordinateTransformations
using Base.Test

img0 = zeros(Normed{UInt16, 16}, 5,5,3,3)
imgpost = zeros(5,5,3,3)
normed1 = Normed{UInt16,16}(1.0)
imgpost[3,3,:,:] = normed1 #We hope the warped array looks like this
img0[3,3,1,:] = normed1 #centered
img0[4,3,2,:] = normed1 #shifted +1 in x
img0[4,4,3,:] = normed1 #shifted +1 in x and y
tfms = [IdentityTransformation(); Translation(1,0); Translation(1,1)]
za  = ZWarpedArray(img0, tfms, Float64; correct_bias=false, sqrt_tfm=false);

for t = 1:size(imgpost,4)
    for z = 1:size(imgpost,3)
        slw = za[:,:,z,t]
        slp = imgpost[:,:,z,t]
        @test !isnan(slw[3,3])
        for i in eachindex(slw)
            if !isnan(slw[i])
                @test slw[i] == slp[i]
            end
        end
    end
end

#test 3D (single stack)
img0 = img0[:,:,:,1]
imgpost = imgpost[:,:,:,1]
za  = ZWarpedArray(img0, tfms, Float64; correct_bias=false, sqrt_tfm=false);

for z = 1:size(imgpost,3)
    slw = za[:,:,z]
    slp = imgpost[:,:,z]
    @test !isnan(slw[3,3])
    for i in eachindex(slw)
        if !isnan(slw[i])
            @test slw[i] == slp[i]
        end
    end
end

#Tests TODO:
##With bias correction
##With bias correction and square root
