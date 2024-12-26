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
    var effects: [TogglableEffect]
    var commandQueue: MTLCommandQueue
    let yuvConversionEffect: YUVToRGBConversionEffect
    
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
        
    }
}
