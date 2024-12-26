/*
See the LICENSE.txt file for this sample’s licensing information.
*/



import Foundation
import simd
import MetalKit
import SwiftUI

final class ContrastBrightnessSaturationEffect: EffectPass {
    private let device: MTLDevice
    private let computePipeline: MTLComputePipelineState

    var settings: ContrastBrightnessSaturationSettings
    
    init(device: MTLDevice) throws {
        self.device = device
        
        let shadersLibrary = device.makeDefaultLibrary()!
        
        self.computePipeline = try device.makeComputePipelineState(function: shadersLibrary.makeFunction(name: "contrastBrightnessSaturationCS")!)
        
        self.settings = ContrastBrightnessSaturationSettings(contrast: 1.0, brightness: 0.0, saturation: 1.0)
    }
    
    var name: String {
        "Contrast, brightness, saturation"
    }
    
    func writeCommands(cb: MTLCommandBuffer, target: MTLTexture) {
        guard let computeEncoder = cb.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(self.computePipeline)
        
        computeEncoder.setTexture(target, index: 0)
        
        computeEncoder.setBytes(&self.settings, length: MemoryLayout<ContrastBrightnessSaturationSettings>.size, index: 0)
        
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
                binding: .init(get: { self.settings.brightness }, set: { self.settings.brightness = $0 }),
                name: "Brightness",
                step: 0.01,
                range: -1 ... 1,
                value: 0.0
            ),
            SliderParameters(
                binding: .init(get: { self.settings.contrast }, set: { self.settings.contrast = $0 }),
                name: "Contrast",
                step: 0.01,
                range: 0 ... 2,
                value: 1.0
            ),
            SliderParameters(
                binding: .init(get: { self.settings.saturation }, set: { self.settings.saturation = $0 }),
                name: "Saturation",
                step: 0.01,
                range: 0 ... 2,
                value: 1.0
            )
        ]
    }
}

/// Ceiling division, e.g. `divUp(10, 3)` is `4`
func divUp(_ lhs: Int, _ rhs: Int) -> Int {
    (lhs + rhs - 1) / rhs
}

/// Ceiling division, e.g. `divUp(10, 3)` is `4`
func divUp(_ lhs: MTLSize, _ rhs: MTLSize) -> MTLSize {
    MTLSize(
        width: divUp(lhs.width, rhs.width),
        height: divUp(lhs.height, rhs.height),
        depth: divUp(lhs.depth, rhs.depth)
    )
}
