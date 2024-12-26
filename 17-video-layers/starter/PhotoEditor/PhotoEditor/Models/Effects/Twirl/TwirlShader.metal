/*
See the LICENSE.txt file for this sample’s licensing information.
*/



#include <metal_stdlib>
using namespace metal;

#include "./TwirlSettings.h"

kernel void twirlCS(
    texture2d<float, access::write> targetTexture [[texture(0)]],
    texture2d<float, access::sample> srcTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]],
    constant TwirlSettings* settings [[buffer(0)]]
) {
    // UV coordinates of the current pixel.
    float2 uv = float2(gid) / float2(targetTexture.get_width(), targetTexture.get_height());
    
    // Center of UV cooridnates.
    float2 center = float2(0.5, 0.5);
    
    // Here we make a vector from center to the pixel we process.
    float2 vector = uv - center;
    
    float angleFactor = 1.0 - smoothstep(0.0, 1.0, metal::length(vector) / settings->radius);
    
    float twirlAngle = settings->angle * angleFactor;  // Apply the factor to the angle.
    
    // Rotation matrix.
    float2x2 rotation = float2x2(
        metal::cos(twirlAngle), metal::sin(twirlAngle),
        -metal::sin(twirlAngle), metal::cos(twirlAngle)
    );
    
    float2 rotatedVector = vector * rotation;
    
    float2 rotatedUv = center + rotatedVector;
    
    constexpr sampler linearSampler(mag_filter::linear, min_filter::linear);
    
    targetTexture.write(srcTexture.sample(linearSampler, rotatedUv), gid);
}


