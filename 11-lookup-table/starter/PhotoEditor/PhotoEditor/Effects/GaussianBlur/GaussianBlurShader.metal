/*
See the LICENSE.txt file for this sample’s licensing information.
*/



#include <metal_stdlib>
using namespace metal;

#include <metal_stdlib>
using namespace metal;

#include "../../CommonShaders/Colors.h"

float3 calculateGaussianBlur(
    float2 uv,
    int samplesCount,
    constant float *weights,
    constant float *offsets,
    texture2d<float, access::sample> blurSrc,
    float2 direction
) {
    constexpr sampler textureSampler(filter::linear, address::clamp_to_edge, coord::pixel);
    
    float3 value = blurSrc.sample(textureSampler, uv).rgb * weights[0];
    
    for (int i = 1; i < samplesCount; i++) {
        // Apply samples from both sides
        
        float2 uv1 = uv + offsets[i] * direction;
        value += blurSrc.sample(textureSampler, uv1).rgb * weights[i];
        
        float2 uv2 = uv - offsets[i] * direction;
        value += blurSrc.sample(textureSampler, uv2).rgb * weights[i];
    }
    
    return value;
}

kernel void gaussianBlurVerticalCS(
    texture2d<float, access::read_write> targetTexture [[texture(0)]],
    texture2d<float, access::sample> blurSrc [[texture(1)]],
    uint2 gid [[thread_position_in_grid]],
    constant int *samplesCount [[buffer(0)]],
    constant float *weights [[buffer(1)]],
    constant float *offsets [[buffer(2)]]
) {
    float2 uv = float2(gid) + float2(0.5, 0.5);
    
    float3 value = calculateGaussianBlur(uv, *samplesCount, weights, offsets, blurSrc, float2(0.0, 1.0));
    
    targetTexture.write(float4(value, 1.0), gid);
}

kernel void gaussianBlurHorizontalCS(
    texture2d<float, access::read_write> targetTexture [[texture(0)]],
    texture2d<float, access::sample> blurSrc [[texture(1)]],
    uint2 gid [[thread_position_in_grid]],
    constant int *samplesCount [[buffer(0)]],
    constant float *weights [[buffer(1)]],
    constant float *offsets [[buffer(2)]]
) {
    
    // UV coordinates of the current pixel.
    float2 uv = float2(gid) + float2(0.5, 0.5);
    
    float3 value = calculateGaussianBlur(uv, *samplesCount, weights, offsets, blurSrc, float2(1.0, 0.0));
    
    targetTexture.write(float4(value, 1.0), gid);
}

float3 calculateGaussianBlur(
    float2 uv,
    int samplesCount,
    constant float *weights,
    texture2d<float, access::sample> blurSrc,
    float2 direction
) {
    constexpr sampler textureSampler(filter::linear, address::clamp_to_edge, coord::pixel);
    
    float3 value = blurSrc.sample(textureSampler, uv).rgb * weights[0];
    
    for (int i = 1; i < samplesCount; i++) {
        // Apply samples from both sides
        
        float2 uv1 = uv + float(i) * direction;
        value += blurSrc.sample(textureSampler, uv1).rgb * weights[i];
        
        float2 uv2 = uv - float(i) * direction;
        value += blurSrc.sample(textureSampler, uv2).rgb * weights[i];
    }
    
    return value;
}
