/*
See the LICENSE.txt file for this sample’s licensing information.
*/



#include <metal_stdlib>
using namespace metal;

#include "../CommonShaders/Colors.h"

struct VertexOutput {
    float4 position [[position]];
    float2 uv;
    float2 bgUv;
};

vertex VertexOutput layerVS(const uint vertexID [[ vertex_id ]],
                            constant float4x4& transform [[ buffer(0) ]]) {
    // The vertices positions placement:
    //
    // (-1.0, 1.0)           (1.0, 1.0)
    //
    //     0/5--------------------1
    //      | \                   |
    //      |    \                |
    //      |       \             |
    //      |          \          |
    //      |             \       |
    //      |                \    |
    //      |                   \ |
    //      4--------------------2/3
    //
    // (-1.0, -1.0)          (1.0, -1.0)
    //
    float2 quadCornersPosition[6] = { float2(-1.0, 1.0), float2(1.0, 1.0), float2(1.0, -1.0), float2(1.0, -1.0), float2(-1.0, -1.0), float2(-1.0, 1.0) };
    float2 quadCornersUv[6] = { float2(0.0, 0.0), float2(1.0, 0.0), float2(1.0, 1.0), float2(1.0, 1.0), float2(0.0, 1.0), float2(0.0, 0.0) };
    
    // Get the position and uv for the current vertex
    
    float4 cornerPosition = float4(quadCornersPosition[vertexID], 0.0, 1.0);
    float2 cornerUv = quadCornersUv[vertexID];
    
    // Apply the transform to the position
    float4 position = transform * cornerPosition;
    
    // Calculate background UV
    
    // Convert position to Normalized Device Coordinates
    float3 ndc = position.xyz / position.w;
    
    // Convert from NDC space to UV space
    float2 bgUv = (ndc.xy + 1.0) / 2.0;
    bgUv.y = 1.0 - bgUv.y;
    
    return {
        position,
        cornerUv,
        bgUv
    };
}

fragment float4 layerNormalBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 blended = layerColor.rgb;
    
    float alpha = layerColor.a * opacity;
    
    float3 output = mix(bgColor, blended, alpha);
    
    return float4(output, 1.0);
}
