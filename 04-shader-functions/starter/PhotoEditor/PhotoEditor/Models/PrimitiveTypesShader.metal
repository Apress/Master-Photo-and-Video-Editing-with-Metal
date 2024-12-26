/*
See the LICENSE.txt file for this sample’s licensing information.
*/

    

#include <metal_stdlib>
using namespace metal;

float xPositionInViewport(float x, vector_float2 viewportSize);
float yPositionInViewport(float y, vector_float2 viewportSize);

struct Vertex {
    float4 position [[position]];
    float4 color;
};

vertex Vertex shaderViewportPositionedVertex(constant Vertex *vertices [[ buffer(0) ]],
                           constant vector_uint2 *viewportSizePointer [[ buffer(1) ]],
                                             uint vid [[ vertex_id ]]) {
    Vertex in = vertices[vid];
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    Vertex out;
    out.position = float4(xPositionInViewport(in.position.x, viewportSize),
                          yPositionInViewport(in.position.y, viewportSize), 0, 1);
    out.color = in.color;
    return out;
}

struct PointVertex {
    float4 position [[position]];
    float4 color;
    float size [[point_size]];
};

vertex PointVertex pointShaderViewportPositionedVertex(constant Vertex *vertices [[ buffer(0) ]],
                           constant vector_uint2 *viewportSizePointer [[ buffer(1) ]],
                           uint vid [[ vertex_id ]]) {
    Vertex in = vertices[vid];
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    PointVertex out;
    out.position = float4(xPositionInViewport(in.position.x, viewportSize),
                          yPositionInViewport(in.position.y, viewportSize), 0, 1);
    out.color = in.color;
    out.size = 20;
    return out;
};

fragment half4 pointShaderFragment(PointVertex point_data [[ stage_in ]],
                                                    float2 pointCoord  [[ point_coord ]])
{
    float dist = length(pointCoord - float2(0.5));
    float4 out_color = point_data.color;
    out_color.a = 1.0 - smoothstep(0.4, 0.5, dist);
    return half4(out_color);
};

float xPositionInViewport(float x, vector_float2 viewportSize) {
    float halfWidth = viewportSize.x / 2;
    float targetX = (x / halfWidth) - 1.0;
    if (x == halfWidth) {
        targetX = 0;
    }
    return targetX;
}

float yPositionInViewport(float y, vector_float2 viewportSize) {
    float halfHeight = viewportSize.y / 2;
    float targetY = 1.0 - (y / halfHeight);
    if (y == halfHeight) {
        targetY = 0;
    }
    return targetY;
}
