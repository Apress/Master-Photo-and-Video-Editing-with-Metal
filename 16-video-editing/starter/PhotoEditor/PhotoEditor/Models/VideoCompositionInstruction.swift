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
    
}
