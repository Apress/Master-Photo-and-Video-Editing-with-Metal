/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import simd
import SwiftUI
import CoreGraphics
import MetalKit
import Combine

class TextureProjectionTransformationRenderingTool: ObservableObject, RenderingTool {
    
    @Published var fov: Float
    @Published var aspect: Float
    @Published var translationZ: Float
    @Published var rotationZ: Float
    @Published var rotationY: Float
    
    struct EyePosition: Equatable {
        var x: Float
        var y: Float
        var z: Float
            
        var simd: SIMD3<Float> {
            return SIMD3(x, y, z)
        }
        
        static func == (lhs: EyePosition, rhs: EyePosition) -> Bool {
            return lhs.simd == rhs.simd
        }
    }
    
    @Published var eyePosition: EyePosition

    private(set) var device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    
    private var matricesBindings = Set<AnyCancellable>()
    
    private var projectionTransformationMatrix: matrix_float4x4
    private var transformationMatrix: matrix_float4x4
    private(set) var texture: MTLTexture?
    private var canvasSize: CGSize = .zero
    
    init() {
        self.fov = 70.0
        self.aspect = 1.0
        self.translationZ = 3.0
        self.rotationY = .zero
        self.rotationZ = .zero
        
        self.projectionTransformationMatrix = matrix_float4x4(perspective: 180, aspect: 1.0)
        self.transformationMatrix = matrix_float4x4(translation: .init(.zero, .zero, 3))
        self.eyePosition = .init(x: .zero, y: .zero, z: -5.0)
        self.device = MTLCreateSystemDefaultDevice()!
        setupBindings()
    }
    
    deinit {
        matricesBindings.forEach({ $0.cancel() })
        matricesBindings.removeAll()
    }
    
    private func setupBindings() {
        $fov.removeDuplicates().combineLatest($aspect.removeDuplicates())
            .map({ matrix_float4x4(perspective: $0.0, aspect: $0.1) })
            .assign(to: \.projectionTransformationMatrix, on: self)
            .store(in: &matricesBindings)
        
        $rotationY.removeDuplicates()
            .combineLatest($translationZ.removeDuplicates())
            .map({ matrix_float4x4(translation: .init(.zero, .zero, $0.1)) * matrix_float4x4(rotation: .init(.zero, .zero, $0.0)) })
            .assign(to: \.transformationMatrix, on: self)
            .store(in: &matricesBindings)
    }
            
    func handleRenderEncoder(encoder: MTLRenderCommandEncoder, metalView mtkView: MTKView, viewportSize: CGSize) {
        createPipelineStateIfNeeded(metalView: mtkView)
        self.canvasSize = viewportSize
        guard let pipelineState = self.pipelineState, let texture else { return }
        
        encoder.setRenderPipelineState(pipelineState)
        
        encoder.setViewport(MTLViewport(
            originX: .zero,
            originY: .zero,
            width: Double(viewportSize.width),
            height: Double(viewportSize.height),
            znear: .zero,
            zfar: 1.0
        ))
        
        encoder.setVertexBytes(&transformationMatrix,
                               length: MemoryLayout<matrix_float4x4>.stride,
                               index: 1)
        
        let textureVertices: [TextureVertex] = []

        encoder.setVertexBytes(&projectionTransformationMatrix,
                               length: MemoryLayout<matrix_float4x4>.stride,
                               index: 2)
        
        var viewMatrix = matrix_float4x4(cameraEyePosition: self.eyePosition.simd)
        encoder.setVertexBytes(&viewMatrix,
                               length: MemoryLayout<matrix_float4x4>.stride,
                               index: 3)
        
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: textureVertices.count)
    }

    private func createPipelineStateIfNeeded(metalView mtkView: MTKView) {
        guard self.pipelineState == nil else { return }
        let defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "textureProjectionTransformVertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "textureFragmentShader")

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
