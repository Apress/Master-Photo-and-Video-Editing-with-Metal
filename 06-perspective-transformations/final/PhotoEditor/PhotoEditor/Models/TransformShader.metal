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
                                             constant float4x4 &transformMatrix [[buffer(1)]],
                                             uint vid [[vertex_id]]) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];

    outVertex.position = transformMatrix * inVertex.position;
    outVertex.color = inVertex.color;

    return outVertex;
}

vertex VertexOut matrixProjectionTransformVertexShader(const device VertexIn *vertices [[buffer(0)]],
                                                       constant float4x4 &transformMatrix [[buffer(1)]],
                                                       constant float4x4 &projectionMatrix [[buffer(2)]],
                                                       constant float4x4 &viewMatrix [[buffer(3)]],
                                                       uint vid [[vertex_id]]) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];

    outVertex.position = projectionMatrix * viewMatrix * transformMatrix * inVertex.position;
    outVertex.color = inVertex.color;

    return outVertex;
}

fragment half4 fragmentShader(VertexOut in [[stage_in]]) {
    return half4(in.color);
}
