/*
See the LICENSE.txt file for this sample’s licensing information.
*/

#include <metal_stdlib>
using namespace metal;
struct VertexIn {
    float4 position;
    float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut matrixTransformVertexShader(const device VertexIn *vertices [[buffer(0)]],
                                             uint vid [[vertex_id]]) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];

    outVertex.position = inVertex.position;
    outVertex.color = inVertex.color;

    return outVertex;
}

fragment half4 fragmentShader(VertexOut in [[stage_in]]) {
    return half4(in.color);
}
