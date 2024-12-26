/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import simd
import SwiftUI
import MetalKit

class PrimitiveTypesRenderingPipelineTool: RenderingTool {
    private(set) var device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    private var selectedPrimitiveType: MTLPrimitiveType
    private var _viewportSize: vector_uint2 = .zero
    
    init(selectedPrimitiveType: MTLPrimitiveType) {
        self.selectedPrimitiveType = selectedPrimitiveType
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
        
        let vertices: [Vertex]
        
        switch selectedPrimitiveType {
        case .line:
            vertices = [
                Vertex(x: viewportSize.width / 2 - 150, y: viewportSize.height / 2, color: .red),
                Vertex(x: viewportSize.width / 2 + 150, y: viewportSize.height / 2, color: .blue)
            ]
        case .point:
            vertices = [Vertex(x: viewportSize.width / 2, y: viewportSize.height / 2, color: .red)]
        default:
//            vertices = [
//                Vertex(x: viewportSize.width / 2, y: viewportSize.height / 2 - 150, color: .green),
//                Vertex(x: viewportSize.width / 2 - 150, y: viewportSize.height / 2 + 150, color: .red),
//                Vertex(x: viewportSize.width / 2 + 150, y: viewportSize.height / 2 + 150, color: .blue)
//            ]
            vertices = [
                Vertex(x: 200, y: 100, color: .green),
                Vertex(x: 50.0, y: 300, color: .red),
                Vertex(x: 250.0, y: 450, color: .blue)
            ]
        }
        
        let buffer = device.makeBuffer(
            bytes: vertices,
            length: (MemoryLayout<Vertex>.stride * vertices.count) * 2,
            options: .storageModeShared
        )
        // Pass in the parameter data.
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)

        // Pass the viewport size
var viewportSize = vector_uint2(viewportSize.width.int32,
                                viewportSize.height.int32)
let length = (MemoryLayout<vector_uint2>.stride)
encoder.setVertexBytes(&viewportSize,
                       length: length,
                       index: 1)
        
        // Draw the points primitives
        encoder.drawPrimitives(type: selectedPrimitiveType, vertexStart: .zero, vertexCount: vertices.count)
    }
    
    
    private func createPipelineStateIfNeeded(metalView mtkView: MTKView) {
        guard self.pipelineState == nil else { return }
        // Load all the shader files with a .metal file extension in the project.
        let defaultLibrary = device.makeDefaultLibrary()
        
        // Load functions from the library.
        let vertexFunction = defaultLibrary?.makeFunction(name: selectedPrimitiveType == .point ? "pointShaderViewportPositionedVertex" : "shaderViewportPositionedVertex")
        let fragmentFunction = defaultLibrary?.makeFunction(name: selectedPrimitiveType == .point ? "pointShaderFragment" : "shaderFragment")
        
        // Configure a pipeline descriptor that is used to create a pipeline state.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.rasterSampleCount = mtkView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        if selectedPrimitiveType == .point {
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        }
        
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
