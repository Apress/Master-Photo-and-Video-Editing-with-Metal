/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Foundation
import MetalKit
import SwiftUI

final class LayerRenderingTool: RenderingTool {
    let device: MTLDevice

    var layers: [Layer]

    private var pipelineState: MTLRenderPipelineState?

    let whiteTexture: MTLTexture
    
    init(device: MTLDevice) throws {
        self.whiteTexture = makeWhiteTexture(device: device)!
        self.device = device
        self.layers = []
    }

    func render(cb: MTLCommandBuffer, target: MTLTexture) {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = target

        // Compose a final image

        let viewport = MTLViewport(
            originX: .zero,
            originY: .zero,
            width: Double(target.width),
            height: Double(target.height),
            znear: .zero,
            zfar: 1.0
        )

        for (layerIndex, layer) in self.layers.enumerated() {
            let isFirstLayer = layerIndex == 0

            let bgTexture: MTLTexture

            // Pick the background to draw on top of
            if isFirstLayer {
                renderPass.colorAttachments[0].loadAction = .clear
                renderPass.colorAttachments[0].clearColor = MTLClearColor(
                    red: 1.0,
                    green: 1.0,
                    blue: 1.0,
                    alpha: 1.0
                )
                bgTexture = self.whiteTexture
            } else {
                renderPass.colorAttachments[0].loadAction = .load
                bgTexture = target
            }

            if let encoder = cb.makeRenderCommandEncoder(descriptor: renderPass) {
                let pipeline = self.makeAlphaBlendingPipeline(device: device)

                encoder.setRenderPipelineState(pipeline)

                encoder.setViewport(viewport)

                var matrix: matrix_float4x4 = layer.transform.makeMatrix(
                    width: target.width,
                    height: target.height
                )
                var mixFactor: Float = layer.opacity

                encoder.setVertexBytes(&matrix, length: 4 * 4 * 4, index: 0)
                encoder.setFragmentTexture(layer.surface.target, index: 0)
                encoder.setFragmentTexture(bgTexture, index: 1)
                encoder.setFragmentBytes(&mixFactor, length: 4, index: 0)

                encoder.drawPrimitives(
                    type: .triangle,
                    vertexStart: 0,
                    vertexCount: 6
                )

                encoder.endEncoding()
            }
        }
    }

    func handleRenderEncoder(commandBuffer cb: MTLCommandBuffer, metalView: MTKView) {
        guard let currentDrawable = metalView.currentDrawable else { return }

        self.render(cb: cb, target: currentDrawable.texture)
    }

    private func makeAlphaBlendingPipeline(device: MTLDevice) -> MTLRenderPipelineState {
        // Load functions from the library.
        if let renderingPipeline = self.pipelineState {
            return renderingPipeline
        }
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "layerVS")
        let fragmentFunction = library.makeFunction(name: "layerNormalBlendFS")

        let descriptor = MTLRenderPipelineDescriptor()

        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction

        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm_srgb
        descriptor.colorAttachments[0].isBlendingEnabled = false

        let pipeline = try! device.makeRenderPipelineState(descriptor: descriptor)

        return pipeline
    }
}
