/*
See the LICENSE.txt file for this sample’s licensing information.
*/

#include <metal_stdlib>
using namespace metal;


kernel void yuvConversion(texture2d<float, access::write> targetTexture [[texture(0)]],
                                     texture2d<float, access::sample> luminanceTexture [[texture(1)]],
                                     texture2d<float, access::sample> chrominanceTexture [[texture(2)]],
                                     uint2 gid [[thread_position_in_grid]],
                                     constant float4x4& colorConversionMatrix [[ buffer(0) ]])
{
    constexpr sampler sampler;

    float2 textureCoordinate = float2(gid) / float2(targetTexture.get_width(), targetTexture.get_height());

    float y = luminanceTexture.sample(sampler, textureCoordinate).r;
    float2 uv = chrominanceTexture.sample(sampler, textureCoordinate).rg;
    float4 ycc = float4(y, uv, 1.0);
    float4 color = float4((colorConversionMatrix * ycc).rgb, 1.0);
    
    targetTexture.write(clamp(color, 0.0, 1.0), gid);
}
