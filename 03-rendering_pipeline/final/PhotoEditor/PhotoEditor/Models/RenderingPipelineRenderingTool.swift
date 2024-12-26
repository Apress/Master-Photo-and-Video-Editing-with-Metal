/*
See the LICENSE.txt file for this sample’s licensing information.
*/
import Foundation
import simd
import SwiftUI
import MetalKit

class RenderingPipelineRenderingTool: RenderingTool {
    private(set) var device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
    }
    
    func handleRenderEncoder(encoder: MTLRenderCommandEncoder, metalView mtkView: MTKView, viewportSize: CGSize) {
        createPipelineStateIfNeeded(metalView: mtkView)
        guard let pipelineState else { return }
        encoder.setRenderPipelineState(pipelineState)

        // Set the region of the drawable to draw into.
        encoder.setViewport(MTLViewport(
            originX: .zero,
            originY: .zero,
            width: Double(viewportSize.width),
            height: Double(viewportSize.height),
            znear: .zero,
            zfar: 1.0
        ))

        let vertices = [
            Vertex(x: 0.25, y: -0.25, color: .green),
            Vertex(x: -0.25, y: -0.25, color: .red),
            Vertex(x: 0.0, y: 0.25, color: .blue)
        ]

        let buffer = device.makeBuffer(
            bytes: vertices,
            length: (MemoryLayout<Vertex>.stride * vertices.count) * 2,
            options: .storageModeShared
        )
        // Pass in the parameter data.
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)

        // Draw the points primitives
        encoder.drawPrimitives(type: .triangle, vertexStart: .zero, vertexCount: vertices.count)
    }
    
    private func createPipelineStateIfNeeded(metalView mtkView: MTKView) {
        guard self.pipelineState == nil else { return }
        // Load all the shader files with a .metal file extension in the project.
        let defaultLibrary = device.makeDefaultLibrary()

        // Load functions from the library.
        let vertexFunction = defaultLibrary?.makeFunction(name: "shaderVertex")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "shaderFragment")

        // Configure a pipeline descriptor that is used to create a pipeline state.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.rasterSampleCount = mtkView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            // Pipeline State creation could fail if the pipeline descriptor isn't set up properly.
            //  If the Metal API validation is enabled, you can find out more information about what
            //  went wrong.  (Metal API validation is enabled by default when a debug build is run
            //  from Xcode.)
            assertionFailure("Failed to create pipeline state: \(error)")
        }
    }
    
}
