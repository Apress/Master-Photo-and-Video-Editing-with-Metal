/*
See the LICENSE.txt file for this sample’s licensing information.
*/



import Foundation
import VideoToolbox
import AVFoundation
import MetalKit
import CoreMedia
import Metal

private class VideoCompositor: NSObject, AVVideoCompositing {
    private var renderContext: AVVideoCompositionRenderContext?
    
    var sourcePixelBufferAttributes: [String : Any]? =
        [String(kCVPixelBufferPixelFormatTypeKey): [Int(kCVPixelFormatType_32BGRA),
                                                    Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
                                                    Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]]
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] =
        [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]

    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        self.renderContext = newRenderContext
    }

    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        
    }
}


actor VideoComposition {
    private let asset: AVAsset
    private(set) var videoComposition: AVMutableVideoComposition
    
    init(renderingTool: VideoRenderingTool, asset: AVAsset) async throws {
        self.asset = asset.copy() as! AVAsset
        self.videoComposition = try await AVMutableVideoComposition.videoComposition(withPropertiesOf: self.asset)
        self.videoComposition.customVideoCompositorClass = VideoCompositor.self
    }
    
}
