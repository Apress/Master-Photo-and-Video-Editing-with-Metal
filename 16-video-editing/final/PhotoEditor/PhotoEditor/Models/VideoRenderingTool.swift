/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import AVFoundation
import Foundation
import MetalKit
import SwiftUI
import VideoToolbox

final class VideoRenderingTool {
    let device: MTLDevice
    let yuvConversionEffect: YUVToRGBConversionEffect
    var effects: [TogglableEffect]
    var commandQueue: MTLCommandQueue
    var targetTextureDescriptor: MTLTextureDescriptor?

    init(device: MTLDevice) throws {
        self.device = device
        let availableEffects: [any EffectPass] = [try GaussianBlurEffect(device: device),
                                                  try ContrastBrightnessSaturationEffect(device: device),
                                                  try VignetteEffect(device: device),
                                                  try LutColorCorrectionEffect(device: device),
                                                  try TwirlEffect(device: device)]
        self.effects = availableEffects.map { TogglableEffect(effect: $0) }
        self.yuvConversionEffect = try YUVToRGBConversionEffect(device: device)

        if let commandQueue = device.makeCommandQueue() {
            self.commandQueue = commandQueue
        } else {
            throw NSError(domain: "Couldn't initiazlize command queue", code: 500)
        }
    }

    func processTexure(from sourcePixelBuffer: CVPixelBuffer, completionHandler: @escaping (CGImage?) -> Void) {
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let sourceTexture = yuvConversionEffect.convertedTexture(cb: commandBuffer, from: sourcePixelBuffer)
        else { return }

        effects
            .filter { $0.isEnabled }
            .compactMap { $0.effect }
            .forEach {
                $0.writeCommands(cb: commandBuffer,
                                 target: sourceTexture.texture)
            }

        commandBuffer.addCompletedHandler { _ in
            completionHandler(sourceTexture.texture.toImage())
        }

        commandBuffer.commit()
    }
}
