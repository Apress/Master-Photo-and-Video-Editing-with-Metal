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
    
    var settingsView: AnyView {
        AnyView(LutColorCorrectionSettingsView(effect: self))
    }
}

struct LutColorCorrectionSettingsView: View {
    let effect: LutColorCorrectionEffect
    
    @State var intensity: Float = 1.0
    @State var lut: URL? = nil
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Intensity: \(intensity)")
                Slider(value: $intensity, in: 0...1)
            }
            .padding(.horizontal, 18)
            
            HStack {
                    AsyncImage(url: lut, content: { img in
                        img.resizable().frame(width: 24.0, height: 24.0)
                    }, placeholder: {
                        Text("No LUT")
                    })
                MediaPicker(title: "Choose lut", handler: { url in
                    do {
                        try self.effect.loadLut(url)
                        self.lut = url
                    } catch {
                        print("\(error)")
                    }
                })
            }
            .padding(.horizontal, 18)
        }
        .onChange(of: self.intensity) { _oldValue, newValue in
            self.effect.intensity = newValue
        }
    }
}
