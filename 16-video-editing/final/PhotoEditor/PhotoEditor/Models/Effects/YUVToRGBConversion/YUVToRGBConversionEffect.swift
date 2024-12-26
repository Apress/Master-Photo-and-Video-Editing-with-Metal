/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import AVFoundation
import Foundation
import MetalKit
import simd
import SwiftUI
import VideoToolbox

final class YUVToRGBConversionEffect {
    private let device: MTLDevice
    private let computePipeline: MTLComputePipelineState

    // BT.601, which is the standard for SDTV.
    public static let colorConversionMatrixVideoRange = float4x4(
        [1.164384, 1.164384, 1.164384, 0.000000],
        [0.000000, -0.213249, 2.111719, 0.000000],
        [1.792741, -0.532909, 0.000000, 0.000000],
        [-0.973015, 0.301512, -1.133142, 1.000000]
    )

    public static let colorConversionMatrixFullRange = float4x4(
        [1.000000, 1.000000, 1.000000, 0.000000],
        [0.000000, -0.187324, 1.855000, 0.000000],
        [1.574800, -0.468124, 0.000000, 0.000000],
        [-0.790550, 0.329035, -0.931210, 1.000000]
    )

    init(device: MTLDevice) throws {
        self.device = device

        let shadersLibrary = device.makeDefaultLibrary()!

        self.computePipeline = try device.makeComputePipelineState(function: shadersLibrary.makeFunction(name: "yuvConversion")!)
    }

    func convertedTexture(cb: MTLCommandBuffer, from pixelBuffer: CVPixelBuffer) -> Texture? {
        var targetTexture: Texture?
        let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)

        let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
        if pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange || pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
            let luminanceTexture = try? Texture(pixelBuffer: pixelBuffer, device: device, pixelFormat: .r8Unorm, width: bufferWidth, height: bufferHeight, plane: 0)
            let chrominanceTexture = try? Texture(pixelBuffer: pixelBuffer, device: device, pixelFormat: .rg8Unorm, width: bufferWidth / 2, height: bufferHeight / 2, plane: 1)
            if let luminanceTexture = luminanceTexture, let chrominanceTexture = chrominanceTexture {
                let videoTextureWidth = abs(bufferWidth)
                let videoTextureHeight = abs(bufferHeight)

                targetTexture = try? Texture(device: device, width: videoTextureWidth, height: videoTextureHeight)
                if
                    let targetTexture,
                    let computeEncoder = cb.makeComputeCommandEncoder() {
                    computeEncoder.setComputePipelineState(self.computePipeline)
                    var colorConversionMatrix = pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                        ? YUVToRGBConversionEffect.colorConversionMatrixVideoRange
                        : YUVToRGBConversionEffect.colorConversionMatrixFullRange

                    computeEncoder.setTexture(targetTexture.texture, index: 0)
                    computeEncoder.setTexture(luminanceTexture.texture, index: 1)
                    computeEncoder.setTexture(chrominanceTexture.texture, index: 2)

                    computeEncoder.setBytes(&colorConversionMatrix, length: MemoryLayout<float4x4>.size, index: 0)

                    let workgroup = MTLSize(
                        width: computePipeline.threadExecutionWidth,
                        height: computePipeline.maxTotalThreadsPerThreadgroup / computePipeline.threadExecutionWidth,
                        depth: 1
                    )

                    let imageSize = MTLSize(width: videoTextureWidth, height: videoTextureHeight, depth: targetTexture.texture.depth)

                    computeEncoder.dispatchThreadgroups(divUp(imageSize, workgroup), threadsPerThreadgroup: workgroup)

                    computeEncoder.endEncoding()
                }
            }
        } else {
            targetTexture = try! Texture(pixelBuffer: pixelBuffer, device: device)
        }

        return targetTexture
    }
}
