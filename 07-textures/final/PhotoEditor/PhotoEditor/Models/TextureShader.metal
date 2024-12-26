/*
See the LICENSE.txt file for this sample’s licensing information.
*/

#include <metal_stdlib>
using namespace metal;

struct TexturePipelineRasterizerData
{
    float4 position [[position]];
    float2 texcoord;
};

struct TextureVertex
{
    float2 position;
    float2 texcoord;
};

vertex TexturePipelineRasterizerData textureProjectionTransformVertexShader(const uint vertexID [[ vertex_id ]],
                                                                  const device TextureVertex *vertices [[ buffer(0) ]],
                                                                  constant float4x4 &transformMatrix [[buffer(1)]],
                                                                  constant float4x4 &projectionMatrix [[buffer(2)]],
                                                                  constant float4x4 &viewMatrix [[buffer(3)]]) {
    TexturePipelineRasterizerData out;
    TextureVertex inVertex = vertices[vertexID];
    
    float4 position = vector_float4(inVertex.position.x, inVertex.position.y, 0.0, 1.0);
    out.position = projectionMatrix * viewMatrix * transformMatrix * position;
    out.texcoord = inVertex.texcoord;

    return out;
}


fragment float4 textureFragmentShader(TexturePipelineRasterizerData in [[stage_in]], texture2d<float> texture [[texture(0)]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 colorSample = float4(texture.sample(textureSampler, in.texcoord));
    return colorSample;
}
