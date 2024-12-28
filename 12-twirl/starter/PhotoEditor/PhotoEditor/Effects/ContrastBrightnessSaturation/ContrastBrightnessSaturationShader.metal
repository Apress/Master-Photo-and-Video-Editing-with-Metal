/*
See the LICENSE.txt file for this sample’s licensing information.
*/



#include <metal_stdlib>
using namespace metal;

#include "../../CommonShaders/Colors.h"

#include "./ContrastBrightnessSaturationSettings.h"

float3 applyContrastBrightness(float3 rgb, float contrast, float brightness) {
    float3 newColor = contrast * (rgb - 0.5) + 0.5 + brightness;
    return clamp(newColor, 0.0, 1.0);
}

kernel void contrastBrightnessSaturationCS(
    texture2d<float, access::read_write> targetTexture [[texture(0)]],
    uint2 gid [[thread_position_in_grid]],
    constant ContrastBrightnessSaturationSettings* settings [[buffer(0)]]
) {
    float3 rgb = targetTexture.read(gid).rgb;
    
    rgb = applyContrastBrightness(rgb, settings->contrast, settings->brightness);
    
    float3 hsl = colors::rgbToHsl(rgb);
    
    hsl[1] *= settings->saturation;
    
    float3 finalColor = colors::hslToRgb(hsl);
    
    targetTexture.write(float4(finalColor, 1.0), gid);
}
