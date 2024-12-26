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
        
        self.settings = TwirlSettings(radius: 0.25, angle: .pi / 4.0);
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
    
    var parameters: [any FilterParamaters] {
        [
            SliderParameters(
                binding: .init(get: { self.settings.radius }, set: { self.settings.radius = $0 }),
                name: "Radius (uv units):",
                step: 0.01,
                range: 0 ... 0.5,
                value: 0.25
            ),
            SliderParameters(
                binding: .init(get: { rad2deg(self.settings.angle) }, set: { self.settings.angle = deg2rad($0) }),
                name: "Angle (deg):",
                step: 0.01,
                range: 0 ... 360,
                value: 45.0
            ),
        ]
    }
}

func rad2deg(_ rad: Float) -> Float {
    return rad * 180 / .pi
}

func deg2rad(_ deg: Float) -> Float {
    return deg / 180 * .pi
}
