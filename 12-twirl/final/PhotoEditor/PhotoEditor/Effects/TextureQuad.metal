/*
See the LICENSE.txt file for this sample’s licensing information.
*/

#include <metal_stdlib>
using namespace metal;

#include "../CommonShaders/Colors.h"

struct VertexOutput {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOutput fullscreenQuadVS(const uint vertexID [[ vertex_id ]]) {
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
    
    float4 position = float4(quadCornersPosition[vertexID], 0.0, 1.0);
    float2 uv = quadCornersUv[vertexID];
    
    return {
        position,
        uv
    };
}

fragment float4 quadTextureFS(VertexOutput in [[stage_in]], texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 value = texture.sample(textureSampler, in.uv);
    
    // Output linear color, because our render target has sRGB format
    return value;
}
