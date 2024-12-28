/*
See the LICENSE.txt file for this sample’s licensing information.
*/



import Foundation
import simd
import MetalKit
import SwiftUI

final class TwirlEffect: EffectPass {
    private let device: MTLDevice
    
    private let computePipeline: MTLComputePipelineState
    
    private var intermediateTexture: MTLTexture? = nil
    
    var settings: TwirlSettings
    
    init(device: MTLDevice) throws {
        self.device = device
        
        let shadersLibrary = device.makeDefaultLibrary()!
        
        self.computePipeline = try device.makeComputePipelineState(function: shadersLibrary.makeFunction(name: "twirlCS")!)
        
        self.settings = TwirlSettings(radius: 0.25, angle: 3.14 / 4.0);
    }
    
    var name: String {
        "Twirl"
    }
    
    func writeCommands(cb: MTLCommandBuffer, target: MTLTexture) {
        let intermediateTexture: MTLTexture
        
        // Try reuse intermediate texture
        if let i = self.intermediateTexture, i.width == target.width, i.height == target.height, i.pixelFormat == target.pixelFormat {
            intermediateTexture = i
        } else {
            let intermediateTextureDesc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: target.pixelFormat,
                width: target.width,
                height: target.height,
                mipmapped: false
            )
            intermediateTexture = device.makeTexture(descriptor: intermediateTextureDesc)!
            self.intermediateTexture = intermediateTexture
        }
        
        guard let blitEncoder = cb.makeBlitCommandEncoder() else {
            return
        }
        
        blitEncoder.copy(from: target, to: intermediateTexture)
        
        blitEncoder.endEncoding()
        
        guard let computeEncoder = cb.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(self.computePipeline)
        
        computeEncoder.setTexture(target, index: 0)
        
        computeEncoder.setTexture(intermediateTexture, index: 1)
        
        computeEncoder.setBytes(&self.settings, length: MemoryLayout<TwirlSettings>.size, index: 0)
        
        let workgroup = MTLSize(
            width: computePipeline.threadExecutionWidth,
            height: computePipeline.maxTotalThreadsPerThreadgroup / computePipeline.threadExecutionWidth,
            depth: 1
        )
        
        let imageSize = MTLSize(width: target.width, height: target.height, depth: target.depth)
        
        computeEncoder.dispatchThreadgroups(divUp(imageSize, workgroup), threadsPerThreadgroup: workgroup)
        
        computeEncoder.endEncoding()
    }
    
    var settingsView: AnyView {
        AnyView(TwirlSettingsView(effect: self))
    }
}

struct TwirlSettingsView: View {
    let effect: TwirlEffect
    
    @State var radius: Float = 0.25
    @State var angle: Float = 45.0
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Radius (uv units): \(radius)")
                Slider(value: $radius, in: 0...0.5)
            }
            .padding(.horizontal, 18)
            
            VStack(alignment: .leading) {
                Text("Angle: \(angle) deg")
                Slider(value: $angle, in: 0...360)
            }
            .padding(.horizontal, 18)
        }
        .onChange(of: self.radius) { _oldValue, newValue in
            self.effect.settings.radius = newValue
        }
        .onChange(of: self.angle) { _oldValue, newValue in
            self.effect.settings.angle = newValue / 180 * 3.14 // Convert from deg to rad
        }
        
    }
}
