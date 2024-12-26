/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import simd
import MetalKit
import SwiftUI

final class LutColorCorrectionEffect: EffectPass {
    private let device: MTLDevice
    private let computePipeline: MTLComputePipelineState
    private var lut: MTLTexture?

    var intensity: Float
    
    init(device: MTLDevice, intensity: Float = 1.0) throws {
        self.device = device
        
        let shadersLibrary = device.makeDefaultLibrary()!
        
        self.computePipeline = try device.makeComputePipelineState(function: shadersLibrary.makeFunction(name: "lutColorCorrection")!)
        
        self.lut = nil
        
        self.intensity = intensity
    }
    
    func loadLut(_ url: URL) throws {
        self.lut = try MTKTextureLoader(device: self.device).newTexture(URL: url)
    }
    
    var name: String {
        "LUT Color Correction"
    }
    
    func writeCommands(cb: MTLCommandBuffer, target: MTLTexture) {
        // If no LUT is loaded, don't apply any effect
        guard let lut = self.lut else { return }
        
        guard let computeEncoder = cb.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(self.computePipeline)
        
        computeEncoder.setTexture(target, index: 0)
        computeEncoder.setTexture(lut, index: 1)
        
        var intensity = simd_float1(self.intensity);
        computeEncoder.setBytes(&intensity, length: MemoryLayout<simd_float1>.size, index: 0)
        
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
            ImagePickerParameters(name: "Choose LUT", value: "", updater: { url in
                if let url = URL(string: url) {
                    do {
                        try self.loadLut(url)
                    } catch {
                        print("error: \(error)")
                    }
                }
            }),
            SliderParameters(
                binding: .init(get: { self.intensity }, set: { self.intensity = $0 }),
                name: "Intencity",
                step: 0.01,
                range: 0 ... 1,
                value: 1.0
            )
        ]
    }
}
