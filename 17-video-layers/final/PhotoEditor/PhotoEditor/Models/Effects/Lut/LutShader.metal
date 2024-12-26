/*
See the LICENSE.txt file for this sample’s licensing information.
*/


#include <metal_stdlib>
using namespace metal;

#include "../../../CommonShaders/Colors.h"

// Find a new color that corresponds to the input color in the 2D grid `lutTexture`.
// NOTE: The input color must be in sRGB format. Returns linear color.
float3 lookup(float3 color, texture2d<float, access::sample> lutTexture) {
    // Define sampler we will use for LUT sampling.
    constexpr sampler lutSampler(mag_filter::linear, min_filter::linear);
    
    float gridSide = 8.0; // Our grid is 8x8 quads.
    float gridQuads = gridSide * gridSide; // Our grid is square.
    
    float quadIndex = color.b * (gridQuads - 1.0); // Find which quad to use, using blue color.
    
    // Note: since LUT resolution is only 64, we need to blend between its points.
    // That's why we select two quads.
    
    float2 quad1;
    quad1.y = floor(floor(quadIndex) / gridSide); // Y quad offset.
    quad1.x = floor(quadIndex) - (quad1.y * gridSide); // X quad offset.
    
    float2 quad2;
    quad2.y = floor(ceil(quadIndex) / gridSide); // Y quad offset.
    quad2.x = ceil(quadIndex) - (quad2.y * gridSide); // X quad offset.
    
    // Calculate UV coordinates for sampling.
    
    float2 texScale = float2(1.0 / lutTexture.get_width(), 1.0 / lutTexture.get_height());
    float2 pixelCenter = 0.5 * texScale; // We do sample in normalized UV coordinates, so we use this value to adjust sampling point to the pixel center.
    
    // Offset in UV space within the quad.
    float2 inQuadUvOffset = color.rg / gridSide + pixelCenter;
    
    float2 uv1 = quad1 / gridSide + inQuadUvOffset;
    float2 uv2 = quad2 / gridSide + inQuadUvOffset;
    
    // Sample colors and mix samples from quads.

    float3 newColor1 = lutTexture.sample(lutSampler, uv1).rgb;
    float3 newColor2 = lutTexture.sample(lutSampler, uv2).rgb;
    
    float3 newColor = mix(newColor1, newColor2, float(fract(quadIndex)));
    
    return newColor;
}

kernel void lutColorCorrection(
    texture2d<float, access::read_write> targetTexture [[texture(0)]],
    texture2d<float> lutTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]],
    constant float* intensity [[buffer(0)]]
) {
    float3 rgb = targetTexture.read(gid).rgb;
    
    // Since colors in LUT table are positioned in gamma space, we need to convert it to gamma space
    float3 srgb = colors::linearToSRGB(rgb);
    
    float3 newRgb = lookup(srgb, lutTexture);
    
    // NOTE: we mixing `rgb` and `newRgb`.
    // Both are linear rgb, not sRGB, because `lookup` returns linear color.
    float3 finalColor = mix(rgb, newRgb, *intensity);
    
    targetTexture.write(float4(finalColor, 1.0), gid);
}

