/*
See the LICENSE.txt file for this sample’s licensing information.
*/



import Foundation
import MetalKit
import SwiftUI
import Combine

protocol EffectPass {
    /// Name of the effect.
    var name: String { get }
    
    /// Record commands into command buffer for the effect.
    ///
    /// @param target Texture to read input from and write output to.
    func writeCommands(cb: MTLCommandBuffer, target: MTLTexture)
    
    /// SwiftUI view to control effect's settings
    var settingsView: AnyView { get }
}

final class ImageWithEffects: RenderingTool {
    private let originalImage: MTLTexture
    private let renderingImage: MTLTexture
    private var renderPipeline: (MTLRenderPipelineState, MTLRenderPipelineDescriptor)? = nil
    
    let device: MTLDevice
    
    var effects: [EffectPass]
    
    init(device: MTLDevice, image: URL) throws {
        self.device = device
        
        self.originalImage = try MTKTextureLoader(device: device).newTexture(URL: image)
        
        let renderingImageDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: self.originalImage.pixelFormat,
            width: self.originalImage.width,
            height: self.originalImage.height,
            mipmapped: false
        )
        renderingImageDesc.usage = [.shaderRead, .renderTarget, .shaderWrite]
        
        self.renderingImage = device.makeTexture(descriptor: renderingImageDesc)!
        
        self.effects = []
    }
    
    var aspectRatio: CGFloat {
        CGFloat(self.originalImage.width) / CGFloat(self.originalImage.height)
    }
    
    func handleRenderEncoder(commandBuffer cb: MTLCommandBuffer, metalView: MTKView, viewportSize: vector_uint2) {
        
        // Copy original image to our rendering image
        if let blitEncoder = cb.makeBlitCommandEncoder() {
            blitEncoder.copy(from: self.originalImage, to: self.renderingImage)
            blitEncoder.endEncoding()
        }
        
        for effect in self.effects {
            effect.writeCommands(cb: cb, target: self.renderingImage)
        }
        
        // Get render pass from the metal view
        guard let renderPassDescriptor = metalView.currentRenderPassDescriptor else { return }
        
        // Render our texture as quad
        if let renderPassEncoder = cb.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            let pipeline = self.getRenderingPipelineState(metalView: metalView)
            
            renderPassEncoder.setRenderPipelineState(pipeline)
            
            renderPassEncoder.setViewport(MTLViewport(
                originX: .zero,
                originY: .zero,
                width: Double(viewportSize.x),
                height: Double(viewportSize.y),
                znear: .zero,
                zfar: 1.0
            ))
            
            renderPassEncoder.setFragmentTexture(self.renderingImage, index: 0)
            
            renderPassEncoder.drawPrimitives(type: .triangle, vertexStart: .zero, vertexCount: 6)
            renderPassEncoder.endEncoding()
        }
    }
    
    func getRenderingPipelineState(metalView: MTKView) -> MTLRenderPipelineState {
        if let (pipeline, descriptor) = self.renderPipeline {
            let samplesOk = descriptor.rasterSampleCount == metalView.sampleCount
            let formatOk = descriptor.colorAttachments[0].pixelFormat == metalView.colorPixelFormat
            
            if samplesOk && formatOk {
                return pipeline
            }
        }
        
        // Load all the shader files with a .metal file extension in the project.
        let defaultLibrary = device.makeDefaultLibrary()!
        
        // Load functions from the library.
        let vertexFunction = defaultLibrary.makeFunction(name: "fullscreenQuadVS")
        let fragmentFunction = defaultLibrary.makeFunction(name: "quadTextureFS")
        
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.rasterSampleCount = metalView.sampleCount
        
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        descriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        // NOTE: if fails, then it's setup incorrectly
        let pipeline = try! device.makeRenderPipelineState(descriptor: descriptor)
        
        self.renderPipeline = (pipeline, descriptor)
        
        return pipeline
    }
}

final class Controls: ObservableObject {
    @Published var intensity: Float = 1.0
}

struct IdentitiableEffect: Identifiable {
    var effect: EffectPass
    
    let id = UUID()
}

struct EffectsView: View {
    let device: MTLDevice
    
    @State var renderingTool: ImageWithEffects?
    
    @State var effects: [IdentitiableEffect]
    
    init(device: MTLDevice, effects: [EffectPass]) {
        self.device = device
        self.effects = effects.map { IdentitiableEffect(effect: $0) }
    }
    
    var controlsView: some View {
        ScrollView {
            VStack {
                ForEach(self.effects) { effect in
                    Section(effect.effect.name) {
                        effect.effect.settingsView
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .frame(height: 200)
    }
    
    var body: some View {
        Group {
            if let renderingTool = self.renderingTool {
                VStack {
                    MetalView(renderingTool: renderingTool)
                        .aspectRatio(self.renderingTool?.aspectRatio ?? 1.0, contentMode: .fit)
                        .padding()
                    self.controlsView
                }
            } else {
                Text("Pick an image")
            }
        }.toolbar(content: {
            MediaPicker(title: "Choose Image", handler: { url in
                do {
                    let runner = try ImageWithEffects(device: self.device, image: url)
                    runner.effects = self.effects.map { $0.effect }
                    self.renderingTool = runner
                } catch {
                    print("\(error)")
                }
            })
        })
    }
}
