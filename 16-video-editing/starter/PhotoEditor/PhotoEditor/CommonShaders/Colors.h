/*
See the LICENSE.txt file for this sample’s licensing information.
*/


#ifndef Color_h
#define Color_h


#include <metal_stdlib>
using namespace metal;

namespace colors {

// Convert RGB color to HSL.
// All output values are in range [0; 1].
METAL_FUNC float3 rgbToHsl(float3 rgb) {
    float maxColor = max(max(rgb.r, rgb.g), rgb.b);
    float minColor = min(min(rgb.r, rgb.g), rgb.b);
    float delta = maxColor - minColor;
    
    float h = 0.0;
    float s = 0.0;
    float l = (maxColor + minColor) / 2.0;
    
    if (delta != 0) {
        s = (l < 0.5) ? (delta / (maxColor + minColor)) : (delta / (2.0 - maxColor - minColor));
        
        if (rgb.r == maxColor) {
            h = (rgb.g - rgb.b) / delta + (rgb.g < rgb.b ? 6.0 : 0.0);
        } else if (rgb.g == maxColor) {
            h = (rgb.b - rgb.r) / delta + 2.0;
        } else {
            h = (rgb.r - rgb.g) / delta + 4.0;
        }
        
        h /= 6.0;
    }
    
    return float3(h, s, l);
}

METAL_FUNC float hueToRgb(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
    if (t < 1.0/2.0) return q;
    if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
    return p;
}

// Convert HSL to linear RGB.
// Input HSL components must be in range [0; 1].
METAL_FUNC float3 hslToRgb(float3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;
    
    float r, g, b;
    
    if (s == 0) {
        r = g = b = l; // achromatic
    } else {
        float q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        float p = 2 * l - q;
        r = hueToRgb(p, q, h + 1.0/3.0);
        g = hueToRgb(p, q, h);
        b = hueToRgb(p, q, h - 1.0/3.0);
    }
    
    return float3(r, g, b);
}

// If x <= edge returns 1.0, otherwise 0.0 (component-wise).
METAL_FUNC float3 lessThan(float3 x, float3 edge) {
    return float3(x <= edge);
}

// Converts linear rgb to gamma rgb.
METAL_FUNC float3 linearToSRGB(float3 linear) {
    linear = clamp(linear, 0.0f, 1.0f);
    return mix(
       pow(linear * 1.055f, 1.0f / 2.4f) - 0.055f,
       linear * 12.92f,
       lessThan(linear, float3(0.0031308f))
    );
}

// Converts gamma rgb to linear rgb.
METAL_FUNC float3 SRGBToLinear(float3 rgb) {
    rgb = clamp(rgb, 0.f, 1.f);
    return mix(
       pow((rgb + 0.055f) / 1.055f, 2.4f),
       rgb / 12.92f,
       lessThan(rgb, 0.04045f)
    );
}

}

#endif
