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

float4 fragmentBlendingOutput(float3 blended, float3 dst, float4 src, float opacity) {
    float alpha = src.a * opacity;
    float3 output = mix(dst, blended, alpha);
    
    return float4(output, 1.0);
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
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}

fragment float4 layerMultiplyBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 blended = bgColor * layerColor.rgb;
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}

fragment float4 layerScreenBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    float3 white = float3(1.0);
    
    float3 blended = white - ((white - layerColor.rgb) * (white - bgColor));
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}

fragment float4 layerOverlayBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 blended = mix(
        2.0 * layerColor.rgb * bgColor,
        1.0 - 2.0 * (1.0 - bgColor) * (1.0 - layerColor.rgb),
        step(0.5, bgColor)
    );
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}

fragment float4 layerHardLightBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 blended = mix(
        2.0 * layerColor.rgb * bgColor,
        1.0 - 2.0 * (1.0 - bgColor) * (1.0 - layerColor.rgb),
        step(0.5, layerColor.rgb)
    );
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}


fragment float4 layerSoftLightBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 g = mix(
        ((16.0 * bgColor - 12.0) * bgColor + 4) * bgColor,
        sqrt(bgColor),
        step(0.25, bgColor)
    );
    
    float3 blended = mix(
        bgColor - (1.0 - 2.0 * layerColor.rgb) * bgColor * (1.0 - bgColor),
        bgColor + (2.0 * layerColor.rgb - 1.0) * (g - bgColor),
        step(0.5, layerColor.rgb)
    );
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}

fragment float4 layerColorBurnBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 blended = 1.0 - min(1.0, (1.0 - bgColor) / layerColor.rgb);

    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}

fragment float4 layerDarkenBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 blended = min(bgColor, layerColor.rgb);
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}

fragment float4 layerLightenBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 blended = max(bgColor, layerColor.rgb);
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}

fragment float4 layerSubtractBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 blended = float3(bgColor - layerColor.rgb);
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}

fragment float4 layerDifferenceBlendFS(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> bg [[texture(1)]],
    constant float& opacity [[ buffer(0) ]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 layerColor = texture.sample(textureSampler, in.uv);
    // BG color always has alpha = 1.0
    float3 bgColor = bg.sample(textureSampler, in.bgUv).rgb;
    
    float3 blended = abs(bgColor - layerColor.rgb);
    
    return fragmentBlendingOutput(blended, bgColor, layerColor, opacity);
}
