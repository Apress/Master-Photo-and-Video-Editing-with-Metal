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
    
    private var transformBindings: AnyCancellable?
    
    private var translateTransformationMatrix: matrix_float4x4
    private var rotationTransformationMatrix: matrix_float4x4
    private var scaleTransformationMatrix: matrix_float4x4
    private var transformationMatrix: matrix_float4x4
    
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
        
        self.translateTransformationMatrix = matrix_float4x4(translation: .zero)
        self.rotationTransformationMatrix = matrix_float4x4(rotation: .zero)
        self.scaleTransformationMatrix = matrix_float4x4(scale: CGPoint(x: 1.0, y: 1.0))
        self.transformationMatrix = self.translateTransformationMatrix * self.rotationTransformationMatrix * self.scaleTransformationMatrix
        
        setupBindings()
    }
    
    deinit {
        transformBindings?.cancel()
        transformBindings = nil
    }
    
    private func setupBindings() {
        transformBindings = $rotationTransform
            .combineLatest($translateTransformX, $translateTransformY, $scaleTransform)
            .filter({
                $0.0 != self.rotationTransform ||
                $0.1 != self.translateTransformX ||
                $0.2 != self.translateTransformY ||
                $0.3 != self.scaleTransform
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rotation, translationX, translationY, scale in
            
                guard let self else { return }

                print("rotation: \(rotation) translation \(translationX),\(translationY), scale \(scale)")
                self.translateTransformationMatrix = .init(translation: .init(translationX, translationY, .zero))
                self.rotationTransformationMatrix = .init(rotation: .init(0.0, 0.0, rotation.cgFloat.degreesToRadians().float))
                self.scaleTransformationMatrix = .init(scale: .init(x: scale.cgFloat, y: scale.cgFloat))
                self.transformationMatrix = self.translateTransformationMatrix * self.rotationTransformationMatrix * self.scaleTransformationMatrix
            }
    }
        
    func handleRenderEncoder(encoder: MTLRenderCommandEncoder, metalView mtkView: MTKView, viewportSize: CGSize) {
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
        
        encoder.setVertexBytes(&transformationMatrix,
                               length: MemoryLayout<matrix_float4x4>.stride,
                               index: 1)
        
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
