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
    
    var settingsView: AnyView {
        AnyView(ContrastBrightnessSaturationSettingsView(effect: self))
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

struct ContrastBrightnessSaturationSettingsView: View {
    let effect: ContrastBrightnessSaturationEffect
    
    @State var contrast: Float = 1.0
    @State var brightness: Float = 0.0
    @State var saturation: Float = 1.0
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Contrast: \(contrast)")
                Slider(value: $contrast, in: 0...2)
            }
            .padding(.horizontal, 18)
            
            VStack(alignment: .leading) {
                Text("Brightness: \(brightness)")
                Slider(value: $brightness, in: -1...1)
            }
            .padding(.horizontal, 18)
            
            VStack(alignment: .leading) {
                Text("Saturation: \(saturation)")
                Slider(value: $saturation, in: 0...3)
            }
            .padding(.horizontal, 18)
        }
        .onChange(of: self.contrast) { _oldValue, newValue in
            self.effect.settings.contrast = newValue
        }
        .onChange(of: self.brightness) { _oldValue, newValue in
            self.effect.settings.brightness = newValue
        }
        .onChange(of: self.saturation) { _oldValue, newValue in
            self.effect.settings.saturation = newValue
        }
    }
}
