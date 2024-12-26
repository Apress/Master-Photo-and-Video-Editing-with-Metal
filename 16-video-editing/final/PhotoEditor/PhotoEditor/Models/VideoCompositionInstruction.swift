/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import MetalKit
import Metal
import AVFoundation
import VideoToolbox
import simd

class VideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    var timeRange: CMTimeRange
    
    var enablePostProcessing: Bool = false
    
    var containsTweening: Bool = false
    
    var requiredSourceTrackIDs: [NSValue]? = nil
    
    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid

    let renderingTool: VideoRenderingTool
    
    
    init(renderingTool: VideoRenderingTool, timeRange: CMTimeRange) {
        self.timeRange = timeRange
        self.renderingTool = renderingTool
    }
    
    func processPixelBuffer(sourcePixelBuffer: CVPixelBuffer, destinationBuffer: CVPixelBuffer, time: CMTime, finish: @escaping (CVPixelBuffer) -> Void) {
        CVPixelBufferLockBaseAddress(sourcePixelBuffer , .readOnly)
        CVPixelBufferLockBaseAddress(destinationBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        renderingTool.processTexure(from: sourcePixelBuffer) { resultImage in
            guard let resultImage else {
                print("error obtaining cg image")
                finish(sourcePixelBuffer)
                return
            }

            let context = CGContext(data: CVPixelBufferGetBaseAddress(destinationBuffer),
                                    width: resultImage.width,
                                    height: resultImage.height,
                                    bitsPerComponent: resultImage.bitsPerComponent,
                                    bytesPerRow: resultImage.bytesPerRow,
                                    space: resultImage.colorSpace!,
                                    bitmapInfo: resultImage.bitmapInfo.rawValue)

            context?.draw(resultImage, in: CGRect(origin: .zero, size: CGSize(width: resultImage.width, height: resultImage.height)), byTiling: false)
            CATransaction.flush()

            CVPixelBufferUnlockBaseAddress(destinationBuffer, CVPixelBufferLockFlags(rawValue: 0))
            CVPixelBufferUnlockBaseAddress(sourcePixelBuffer, .readOnly)

            finish(destinationBuffer)
        }
    }
}
