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
        guard
            let instruction = asyncVideoCompositionRequest.videoCompositionInstruction as? VideoCompositionInstruction,
            let sourceFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[0].int32Value),
            let destinationBuffer = self.renderContext?.newPixelBuffer()
        else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "incorrect instruction", code: 0))
            return
        }
        
        let time = asyncVideoCompositionRequest.compositionTime
        
        instruction.processPixelBuffer(sourcePixelBuffer: sourceFrame, destinationBuffer: destinationBuffer, time: time) { result in
            asyncVideoCompositionRequest.finish(withComposedVideoFrame: destinationBuffer)
        }
    }
}


actor VideoComposition {
    private let asset: AVAsset
    private(set) var videoComposition: AVMutableVideoComposition
    
    init(renderingTool: VideoRenderingTool, asset: AVAsset) async throws {
        self.asset = asset.copy() as! AVAsset
        self.videoComposition = try await AVMutableVideoComposition.videoComposition(withPropertiesOf: self.asset)
        
        let videoTracks = try await self.asset.loadTracks(withMediaType: .video)
        
        if let composition = self.asset as? AVComposition {
            self.videoComposition.renderSize = composition.naturalSize
        } else {
            var renderSize: CGSize = .zero
            for videoTrack in videoTracks {
                let preferredTransform = try await videoTrack.load(.preferredTransform)
                let size = try await videoTrack.load(.naturalSize).applying(preferredTransform)
                
                renderSize.width = max(renderSize.width, abs(size.width))
                renderSize.height = max(renderSize.height, abs(size.height))
            }
            videoComposition.renderSize = renderSize
        }
        videoComposition.customVideoCompositorClass = VideoCompositor.self
        self.videoComposition.instructions = [VideoCompositionInstruction(renderingTool: renderingTool, timeRange: CMTimeRange(start: .zero, duration: CMTime(value: .max, timescale: 48000)))]
    }
    
}
