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

vertex TexturePipelineRasterizerData matrixTransformTextureVertexShader(const device TextureVertex *vertices [[buffer(0)]],
                              constant float4x4 &transformMatrix [[buffer(1)]],
                              constant float4x4 &orthographicMatrix [[buffer(2)]],
                              uint vid [[vertex_id]]) {
    TexturePipelineRasterizerData outVertex;
    TextureVertex inVertex = vertices[vid];

    outVertex.position = orthographicMatrix * transformMatrix * vector_float4(inVertex.position.x, inVertex.position.y, 0.0, 1.0);
    outVertex.texcoord = inVertex.texcoord;

    return outVertex;
}

METAL_FUNC float4 unpremultiply(float4 s) {
    return float4(s.rgb/max(s.a,0.00001), s.a);
}

METAL_FUNC float4 premultiply(float4 s) {
    return float4(s.rgb * s.a, s.a);
}

//source over blend
METAL_FUNC float4 normalBlend(float4 Cb, float4 Cs) {
    float4 dst = premultiply(Cb);
    float4 src = premultiply(Cs);
    return unpremultiply(src + dst * (1.0 - src.a));
}

fragment float4 matrixTransformTextureFragmentShader(TexturePipelineRasterizerData in [[stage_in]],
                              texture2d<float, access::read> backgroundTexture [[texture(1)]],
                              texture2d<float, access::sample> overlayTexture [[texture(2)]],
                                                     constant float *mixturePercent [[buffer(0)]]) {

    sampler quadSampler(mag_filter::linear, min_filter::linear);
    uint2 grid = uint2(uint(backgroundTexture.get_width() * in.position.x), uint(backgroundTexture.get_height() * in.position.y));
    float4 inColor = backgroundTexture.read(grid);
    
    float4 inColor2 = overlayTexture.sample(quadSampler, in.texcoord);//float2(float(in.texcoord.x) / overlayTexture.get_width(), float(in.texcoord.y) / overlayTexture.get_height()));
//    const half4 inColor2 = overlayTexture.read
    inColor2.a = 0.3;//*= (*mixturePercent);
    
//    const half4 outColor(mix(inColor.bgr, inColor2.bgr, inColor2.a * half(*mixturePercent)), inColor.a);
    
    return inColor;//normalBlend(inColor, inColor2);
}

