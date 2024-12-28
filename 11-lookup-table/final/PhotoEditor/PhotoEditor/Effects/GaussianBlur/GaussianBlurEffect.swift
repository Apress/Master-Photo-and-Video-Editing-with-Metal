/*
See the LICENSE.txt file for this sample’s licensing information.
*/



import Foundation
import simd
import MetalKit
import SwiftUI

final class GaussianBlurEffect: EffectPass {
    private let device: MTLDevice
    
    private let computePipelineV: MTLComputePipelineState
    private let computePipelineH: MTLComputePipelineState
    
    private var blurIntermediate: MTLTexture? = nil
    
    var kernel: GaussianBlurKernel = GaussianBlurKernel(radius: 10.0, sizeMultiplier: 2.0)
    
    init(device: MTLDevice) throws {
        self.device = device
        
        let shadersLibrary = device.makeDefaultLibrary()!
        
        self.computePipelineV = try device.makeComputePipelineState(function: shadersLibrary.makeFunction(name: "gaussianBlurVerticalCS")!)
        self.computePipelineH = try device.makeComputePipelineState(function: shadersLibrary.makeFunction(name: "gaussianBlurHorizontalCS")!)
    }
    
    var name: String {
        "Gaussian blur"
    }
    
    func writePass(cb: MTLCommandBuffer, pipeline: MTLComputePipelineState, blurSrc: MTLTexture, blurOutput: MTLTexture) {
        guard let encoder = cb.makeComputeCommandEncoder() else { return }
        
        encoder.setComputePipelineState(pipeline)
        
        encoder.setTexture(blurOutput, index: 0)
        
        encoder.setTexture(blurSrc, index: 1)
        
        var kernelSize: Int32 = Int32(self.kernel.kernelSize)
        var weights: [Float] = self.kernel.weights
        var offsets: [Float] = self.kernel.offsets
        
        encoder.setBytes(&kernelSize, length: MemoryLayout<Int32>.size, index: 0)
        encoder.setBytes(&weights, length: MemoryLayout<Float>.stride * self.kernel.kernelSize, index: 1)
        encoder.setBytes(&offsets, length: MemoryLayout<Float>.stride * self.kernel.kernelSize, index: 2)
        
        let workgroup = MTLSize(
            width: pipeline.threadExecutionWidth,
            height: pipeline.maxTotalThreadsPerThreadgroup / pipeline.threadExecutionWidth,
            depth: 1
        )
        
        let imageSize = MTLSize(width: blurOutput.width, height: blurOutput.height, depth: blurOutput.depth)
        
        encoder.dispatchThreadgroups(divUp(imageSize, workgroup), threadsPerThreadgroup: workgroup)
        
        encoder.endEncoding()
    }
    
    func writeCommands(cb: MTLCommandBuffer, target: MTLTexture) {
        let blurIntermediate: MTLTexture
        
        // Try reuse intermediate texture
        if let bi = self.blurIntermediate, bi.width == target.width, bi.height == target.height, bi.pixelFormat == target.pixelFormat {
            blurIntermediate = bi
        } else {
            let blurIntermediateDesc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: target.pixelFormat,
                width: target.width,
                height: target.height,
                mipmapped: false
            )
            blurIntermediateDesc.usage = [.shaderWrite, .shaderRead]
            blurIntermediate = device.makeTexture(descriptor: blurIntermediateDesc)!
            self.blurIntermediate = blurIntermediate
        }
        
        self.writePass(cb: cb, pipeline: self.computePipelineV, blurSrc: target, blurOutput: blurIntermediate)
        
        self.writePass(cb: cb, pipeline: self.computePipelineH, blurSrc: blurIntermediate, blurOutput: target)
    }
    
    var settingsView: AnyView {
        AnyView(GaussianBlurSettingsView(effect: self))
    }
}

struct GaussianBlurSettingsView: View {
    let effect: GaussianBlurEffect
    
    @State var radius: Float = 10.0
    @State var sizeMultiplier: Float = 2.0
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Radius (sigma): \(radius)")
                Slider(value: $radius, in: 0...100)
            }
            .padding(.horizontal, 18)
            
            VStack(alignment: .leading) {
                Text("Size multiplier: \(sizeMultiplier). Good values are from 2 to 3.")
                Slider(value: $sizeMultiplier, in: 0...5)
            }
            .padding(.horizontal, 18)
            
            VStack(alignment: .leading) {
                Text("Total samples per pixel: \(self.effect.kernel.samplesCount * 2)")
            }
            .padding(.horizontal, 18)
        }
        .onChange(of: self.radius) { _oldValue, newValue in
            self.effect.kernel = GaussianBlurKernel(radius: newValue, sizeMultiplier: self.sizeMultiplier)
        }
        .onChange(of: self.sizeMultiplier) { _oldValue, newValue in
            self.effect.kernel = GaussianBlurKernel(radius: self.radius, sizeMultiplier: newValue)
        }
    }
}

struct GaussianBlurKernel {
    // NOTE: Full gaussian kernel is mirrored, we store only center + trailing edge.
    
    let weights: [Float]
    let offsets: [Float]
    
    init(radius: Float, sizeMultiplier: Float = 2.5) {
        let k = gaussianKernel(sigma: radius, multiplier: sizeMultiplier)
        
        let (w, o) = optimizeKernel(weights: k)
        
        assert(w.count == o.count)
        
        self.weights = w
        self.offsets = o
    }
    
    var kernelSize: Int {
        self.weights.count
    }
    
    var samplesCount: Int {
        self.kernelSize * 2 - 1
    }
}

struct GaussianBlurKernel0 {
    // NOTE: Full gaussian kernel is mirrored, we store only center + trailing edge.
    
    let weights: [Float]
    
    init(sigma: Float, multiplier: Float = 2.5) {
        self.weights = gaussianKernel(sigma: sigma, multiplier: multiplier)
    }
    
    var halfSize: Int {
        self.weights.count
    }
    
    var samplesCount: Int {
        self.halfSize * 2 - 1
    }
}

// Calculate the 1D gaussian kernel.
//
// The resulting arrays contains center and weight from the trailing size of the kernel,
// because the full gaussian kernel is mirrored.
func gaussianKernel(sigma: Float, multiplier: Float) -> [Float] {
    // Gaussian function does not expect 0 as sigma value.
    // Handle this case manually.
    if sigma == 0.0 {
        return [1.0]
    }
    
    let halfSize = 1 + Int(ceil(sigma * multiplier))
    
    var kernel: [Float] = []
    
    for i in 0..<halfSize {
        let x = Float(i)
        
        let exponent = -(x * x) / (2 * sigma * sigma)
        let coefficient = 1 / (sqrt(2 * Float.pi) * sigma)
        let w = coefficient * exp(exponent)
        
        kernel.append(w)
    }
    
    // Sum the kernel values
    
    var sum = kernel[0] // Value in center of the kernel
    
    for k in kernel[1...] {
        // We don't store both sides of the kernel, since it is mirrored.
        // So we need to add value from both sides, i.e. double it.
        sum += k * 2.0
    }
    
    // Normalize the kernel. We need all kernel values to sum up to 1.0
    
    let normalizedKernel = kernel.map { $0 / sum }
    
    return normalizedKernel
}

func mergeWeights(
    w1: Float,
    w2: Float,
    o1: Float,
    o2: Float
) -> (Float, Float) {
    let w = w1 + w2
    let o = (w1 * o1 + w2 * o2) / w
    return (w, o)
}

func optimizeKernel(weights oldWeights: [Float]) -> ([Float], [Float]) {
    var weights: [Float] = [oldWeights[0]]
    var offsets: [Float] = [0.0]
    
    var i = 1
    
    while i < oldWeights.count {
        let hasNext = (i + 1) < oldWeights.count
        
        if hasNext {
            let w1 = oldWeights[i]
            let w2 = oldWeights[i + 1]
            
            let (w, o) = mergeWeights(
                w1: w1,
                w2: w2,
                o1: Float(i),
                o2: Float(i + 1)
            )
            
            weights.append(w)
            offsets.append(o)
            
            i += 2
        } else {
            weights.append(oldWeights[i])
            offsets.append(Float(i))
            
            i += 1
        }
    }
    
    return (weights, offsets)
}
