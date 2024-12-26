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
    
    var containsTweening: Bool = true
    
    var requiredSourceTrackIDs: [NSValue]?
    
    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid

    let renderingTool: LayerRenderingTool
    
    
    init(renderingTool: LayerRenderingTool, timeRange: CMTimeRange) {
        self.timeRange = timeRange
        self.renderingTool = renderingTool
        self.requiredSourceTrackIDs = renderingTool.layers
            .enumerated()
            .filter({ $0.element.surface is VideoContentLayerSurface })
            .compactMap({ CMPersistentTrackID($0.offset + 1) })
            .filter({ $0 != kCMPersistentTrackID_Invalid })
            .compactMap({ $0 as NSValue })
    }
}
