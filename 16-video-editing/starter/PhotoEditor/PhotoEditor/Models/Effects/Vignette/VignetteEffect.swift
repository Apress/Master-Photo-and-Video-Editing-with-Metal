/*
See the LICENSE.txt file for this sample’s licensing information.
*/



import Foundation
import simd
import MetalKit
import SwiftUI

final class VignetteEffect: EffectPass {
    private let device: MTLDevice
    private let computePipeline: MTLComputePipelineState
    
    var settings: VignetteSettings
    
    init(device: MTLDevice) throws {
        self.device = device
        
        let shadersLibrary = device.makeDefaultLibrary()!
        
        self.computePipeline = try device.makeComputePipelineState(function: shadersLibrary.makeFunction(name: "applyVignette")!)
        
        self.settings = VignetteSettings(offset: 0.3, softness: 0.5)
    }
    
    var name: String {
        "Vignette"
    }
    
    func writeCommands(cb: MTLCommandBuffer, target: MTLTexture) {
        guard let computeEncoder = cb.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(self.computePipeline)
        
        computeEncoder.setTexture(target, index: 0)
        
        computeEncoder.setBytes(&self.settings, length: MemoryLayout<VignetteSettings>.size, index: 0)
        
        let workgroup = MTLSize(
            width: computePipeline.threadExecutionWidth,
            height: computePipeline.maxTotalThreadsPerThreadgroup / computePipeline.threadExecutionWidth,
            depth: 1
        )
        
        let imageSize = MTLSize(width: target.width, height: target.height, depth: target.depth)
        
        computeEncoder.dispatchThreadgroups(divUp(imageSize, workgroup), threadsPerThreadgroup: workgroup)
        
        computeEncoder.endEncoding()
    }
    
    var parameters: [any FilterParamaters]  {
        [
            SliderParameters(
                binding: .init(get: { self.settings.offset }, set: { self.settings.offset = $0 }),
                name: "Offset",
                step: 0.01,
                range: 0 ... 1,
                value: 1.0
            ),
            SliderParameters(
                binding: .init(get: { self.settings.softness }, set: { self.settings.softness = $0 }),
                name: "Softness",
                step: 0.01,
                range: 0 ... 1,
                value: 1.0
            )
        ]
    }
}
