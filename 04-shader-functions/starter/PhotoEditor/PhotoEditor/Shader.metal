/*
See the LICENSE.txt file for this sample’s licensing information.
*/


#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float4 color;
};

vertex Vertex shaderVertex(constant Vertex *vertices [[ buffer(0) ]], uint vid [[ vertex_id ]]) {
    Vertex out = vertices[vid];

    float2 pos = float2(out.position.x, out.position.y);
    out.position = float4(pos, 0, 1);
    return out;
};

fragment half4 shaderFragment(Vertex input [[ stage_in ]]) {
    return half4(input.color);
};
