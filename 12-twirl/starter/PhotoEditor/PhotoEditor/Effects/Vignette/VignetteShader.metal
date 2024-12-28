/*
See the LICENSE.txt file for this sample’s licensing information.
*/



#include <metal_stdlib>
using namespace metal;

#include "./VignetteSettings.h"

kernel void applyVignette(
    texture2d<float, access::read_write> targetTexture [[texture(0)]],
    uint2 gid [[thread_position_in_grid]],
    constant VignetteSettings* settings [[buffer(0)]]
) {
    float3 rgb = targetTexture.read(gid).rgb;
    
    // UV coordinates of the current pixel.
    float2 uv = float2(gid) / float2(targetTexture.get_width(), targetTexture.get_height());
    
    // Calculate the distance from the center of the texture.
    float distance = metal::distance(uv, float2(0.5, 0.5));
    
    float darkeningFactor = 1.0 - distance;
    
    // Calculate the vignette effect intensity based on the distance and exposure.
    darkeningFactor = smoothstep(settings->offset, settings->offset + settings->softness, darkeningFactor);
    
    // Apply darkening factor.
    float3 finalColor = rgb * darkeningFactor;
    
    targetTexture.write(float4(finalColor, 1.0), gid);
}
