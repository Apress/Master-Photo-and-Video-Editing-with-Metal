/*
See the LICENSE.txt file for this sample’s licensing information.
*/
import Foundation
import simd
import SwiftUI
import CoreGraphics
import MetalKit
import Combine

class ProjectionTransformationRenderingTool: ObservableObject, RenderingTool {
    
    @Published var fov: Float
    @Published var aspect: Float
    @Published var translationZ: Float
    @Published var rotationY: Float
    
    private(set) var device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    
    private var matricesBindings = Set<AnyCancellable>()
    
    private var transformationMatrix: matrix_float4x4
    
    struct Vertex {
        var position: SIMD4<Float>
        var color: SIMD4<Float>
    }

    init() {
        self.device = MTLCreateSystemDefaultDevice()!

        self.fov = 70.0
        self.aspect = 1.0

        self.translationZ = .zero
        self.rotationY = .zero
        
        self.transformationMatrix = matrix_float4x4(translation: .init(.zero, .zero, .zero))

        setupBindings()
    }
    
    deinit {
        matricesBindings.forEach({ $0.cancel() })
        matricesBindings.removeAll()
    }
    
    private func setupBindings() {
        $rotationY.removeDuplicates()
            .combineLatest($translationZ.removeDuplicates())
            .map({ matrix_float4x4(translation: .init(.zero, .zero, $0.1)) * matrix_float4x4(rotation: .init(.zero, .zero, $0.0)) })
            .assign(to: \.transformationMatrix, on: self)
            .store(in: &matricesBindings)
    }
        
    func handleRenderEncoder(encoder: MTLRenderCommandEncoder, metalView mtkView: MTKView, viewportSize: CGSize) {
        createPipelineStateIfNeeded(metalView: mtkView)
        
        guard let pipelineState = self.pipelineState else { return }
        
        encoder.setRenderPipelineState(pipelineState)

        encoder.setVertexBytes(&transformationMatrix,
                               length: MemoryLayout<matrix_float4x4>.stride,
                               index: 1)
        
        // Define triangle vertices
        let vertices: [Vertex] = [
            Vertex(position: [-0.5, 0.25, 0.0, 1.0], color: [1, 0, 0, 1]),
            Vertex(position: [0.0, -0.5, 0.0, 1.0], color: [0, 1, 0, 1]),
            Vertex(position: [0.5, 0.5, 0.0, 1.0], color: [0, 0, 1, 1])
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
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

}
