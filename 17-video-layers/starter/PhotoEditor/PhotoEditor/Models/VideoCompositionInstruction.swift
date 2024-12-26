/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import AVFoundation
import Foundation
import Metal
import MetalKit
import simd
import VideoToolbox

class VideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    var timeRange: CMTimeRange

    var enablePostProcessing: Bool = false

    var containsTweening: Bool = true

    var requiredSourceTrackIDs: [NSValue]? = nil

    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid

    let renderingTool: LayerRenderingTool

    init(renderingTool: LayerRenderingTool, timeRange: CMTimeRange) {
        self.timeRange = timeRange
        self.renderingTool = renderingTool
    }
}
