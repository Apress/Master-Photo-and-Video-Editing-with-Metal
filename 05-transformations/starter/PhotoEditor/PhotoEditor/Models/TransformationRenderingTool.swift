/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import simd
import SwiftUI
import CoreGraphics
import MetalKit
import Combine

class TransformationRenderingTool: ObservableObject, RenderingTool {
    @Published var translateTransformX: Float
    @Published var translateTransformY: Float
    @Published var rotationTransform: Float
    @Published var scaleTransform: Float
    
    private(set) var device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
        
    struct Vertex {
        var position: SIMD4<Float>
        var color: SIMD4<Float>
    }

    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.translateTransformX = 0.0
        self.translateTransformY = 0.0
        self.rotationTransform = 0.0
        self.scaleTransform = 1.0
        setupBindings()
    }
    
    deinit {

    }
    
    private func setupBindings() {
        
    }
    
    func handleRenderEncoder(encoder: MTLRenderCommandEncoder, metalView mtkView: MTKView, viewportSize: CGSize) {
        guard
            // Obtain a renderPassDescriptor generated from the view's drawable textures
            let renderPassDescriptor = mtkView.currentRenderPassDescriptor
        else { return }

        createPipelineStateIfNeeded(metalView: mtkView)
        
        guard let pipelineState = self.pipelineState else { return }
        encoder.setRenderPipelineState(pipelineState)

        // Define triangle vertices
        let vertices: [Vertex] = [
            Vertex(position: [-0.5, 0.25, 0.0, 1.0], color: [1, 0, 0, 1]),  // Bottom Left
            Vertex(position: [0.0, -0.5, 0.0, 1.0], color: [0, 1, 0, 1]), // Bottom Right
            Vertex(position: [0.5, 0.5, 0.0, 1.0], color: [0, 0, 1, 1])    // Top
        ]

        let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: .storageModeShared)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }

    private func createPipelineStateIfNeeded(metalView mtkView: MTKView) {
        guard self.pipelineState == nil else { return }
        let defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "matrixTransformVertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

}
