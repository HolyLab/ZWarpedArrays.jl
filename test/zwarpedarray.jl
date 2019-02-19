using ZWarpedArrays, Images, CoordinateTransformations
using Test

img0 = zeros(Normed{UInt16, 16}, 5,5,3,3)
imgpost = zeros(5,5,3,3)
normed1 = reinterpret(Normed{UInt16,16}, UInt16(2^8))
imgpost[3,3,:,:] .= normed1 #We hope the warped array looks like this
img0[3,3,1,:] .= normed1 #centered
img0[4,3,2,:] .= normed1 #shifted +1 in x
img0[4,4,3,:] .= normed1 #shifted +1 in x and y
tfms = [IdentityTransformation(); Translation(1,0); Translation(1,1)]
za  = ZWarpedArray(img0, tfms, Float32; correct_bias=false, sqrt_tfm=false);
@test eltype(za[:,:,2,2]) == Float32
za  = ZWarpedArray(img0, tfms, Float64; correct_bias=false, sqrt_tfm=false);
@test eltype(za[:,:,2,2]) == Float64

for t = 1:size(imgpost,4)
    for z = 1:size(imgpost,3)
        slw = za[:,:,z,t]
        slp = imgpost[:,:,z,t]
        @test !isnan(slw[3,3])
        for i in eachindex(slw)
            if !isnan(slw[i])
                @test isapprox(slw[i], slp[i])
            end
        end
    end
end

#test 3D (single stack)
img0t = img0[:,:,:,1]
imgpostt = imgpost[:,:,:,1]
za3  = ZWarpedArray(img0t, tfms, Float64; correct_bias=false, sqrt_tfm=false);

for z = 1:size(imgpostt,3)
    slw = za3[:,:,z]
    slp = imgpostt[:,:,z]
    @test !isnan(slw[3,3])
    for i in eachindex(slw)
        if !isnan(slw[i])
            @test isapprox(slw[i], slp[i])
        end
    end
end

##With bias correction
img0t .+= reinterpret(Normed{UInt16, 16}, UInt16(100))
za  = ZWarpedArray(img0t, tfms, Float64; correct_bias=true, sqrt_tfm=false);

for z = 1:size(imgpostt,3)
    slw = za[:,:,z]
    slp = imgpostt[:,:,z]
    @test !isnan(slw[3,3])
    for i in eachindex(slw)
        if !isnan(slw[i])
            @test isapprox(slw[i], slp[i])
        end
    end
end
##With bias correction and square root
za  = ZWarpedArray(img0t, tfms, Float64; correct_bias=true, sqrt_tfm=true);

for z = 1:size(imgpostt,3)
    slw = za[:,:,z]
    slp = imgpostt[:,:,z]
    @test !isnan(slw[3,3])
    for i in eachindex(slw)
        if !isnan(slw[i])
            @test isapprox(slw[i], sqrt(slp[i]))
        end
    end
end

meta = ImageMeta(img0t)
zm  = ZWarpedArray(meta, tfms, Float64; correct_bias=false, sqrt_tfm=false);
@test isa(zm, ImageMeta)
@test all(data(zm) .== za3)

aa = AxisArray(img0t)
zaa  = ZWarpedArray(aa, tfms, Float64; correct_bias=false, sqrt_tfm=false);
@test isa(zaa, AxisArray)
@test all(data(zaa) .== za3)
