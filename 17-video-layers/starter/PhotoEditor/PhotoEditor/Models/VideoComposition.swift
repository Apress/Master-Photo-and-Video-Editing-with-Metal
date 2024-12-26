/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import AVFoundation
import CoreMedia
import Foundation
import Metal
import MetalKit
import VideoToolbox

private class VideoCompositor: NSObject, AVVideoCompositing {
    private var renderContext: AVVideoCompositionRenderContext?

    var sourcePixelBufferAttributes: [String: Any]? =
        [String(kCVPixelBufferPixelFormatTypeKey): [Int(kCVPixelFormatType_32BGRA),
                                                    Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
                                                    Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]]

    var requiredPixelBufferAttributesForRenderContext: [String: Any] =
        [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        self.renderContext = newRenderContext
    }

    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard
            let instruction = asyncVideoCompositionRequest.videoCompositionInstruction as? VideoCompositionInstruction,
            let commandBuffer = instruction.renderingTool.commandQueue.makeCommandBuffer(),
            let sourceFrame = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[0].int32Value),
            let destinationBuffer = self.renderContext?.newPixelBuffer(),
            let targetTexture = try? Texture(pixelBuffer: destinationBuffer, device: instruction.renderingTool.device)
        else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "incorrect instruction", code: 0))
            return
        }
        CVPixelBufferLockBaseAddress(destinationBuffer, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferLockBaseAddress(sourceFrame, .readOnly)
        
        let layer = instruction.renderingTool.layers
            .first(where: { $0.surface is VideoContentLayerSurface })?
            .surface as! VideoContentLayerSurface
        
        layer.processTexure(from: sourceFrame, commandBuffer: commandBuffer)
    
        let resultTexture = targetTexture.texture
        resultTexture.label = "target_pixelBuffer"
        instruction.renderingTool.render(cb: commandBuffer, target: resultTexture)

        commandBuffer.addCompletedHandler { _ in
            guard
                let cgImage = resultTexture.toImage()
            else {
                print("error obtaining cg image")
                asyncVideoCompositionRequest.finish(withComposedVideoFrame: destinationBuffer)
                return
            }

            let context = CGContext(data: CVPixelBufferGetBaseAddress(destinationBuffer),
                                    width: cgImage.width,
                                    height: cgImage.height,
                                    bitsPerComponent: cgImage.bitsPerComponent,
                                    bytesPerRow: cgImage.bytesPerRow,
                                    space: cgImage.colorSpace!,
                                    bitmapInfo: cgImage.bitmapInfo.rawValue)

            context?.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height)), byTiling: false)
            CATransaction.flush()

            CVPixelBufferUnlockBaseAddress(sourceFrame, .readOnly)
            CVPixelBufferUnlockBaseAddress(destinationBuffer, CVPixelBufferLockFlags(rawValue: 0))

            asyncVideoCompositionRequest.finish(withComposedVideoFrame: destinationBuffer)
        }

        commandBuffer.commit()
    }
}

actor VideoComposition {
    private(set) var renderingTool: LayerRenderingTool
    private(set) var composition: AVMutableComposition
    private(set) var videoComposition: AVMutableVideoComposition

    init(renderingTool: LayerRenderingTool, asset: AVAsset) async throws {
        self.composition = AVMutableComposition()
        self.renderingTool = renderingTool

        self.videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = VideoCompositor.self
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: 1920, height: 1080)

        let videoLayerSurface = try await VideoContentLayerSurface(device: renderingTool.device, asset: asset)
        try await self.addVideoLayer(videoLayerSurface: videoLayerSurface)

        let instruction = VideoCompositionInstruction(renderingTool: self.renderingTool, timeRange: videoLayerSurface.timeRange)
        videoComposition.instructions = [instruction]
    }

    func addVideoTrack(asset: AVAsset) async throws {
        let videoLayerSurface = try await VideoContentLayerSurface(device: renderingTool.device, asset: asset)
        try await self.addVideoLayer(videoLayerSurface: videoLayerSurface)
        let videoLayersDuration = self.renderingTool.layers.compactMap { $0.surface as? VideoContentLayerSurface }.map { $0.timeRange }
        let maxDuration = videoLayersDuration.sorted(by: { $0.duration < $1.duration }).last
        videoComposition.instructions = [VideoCompositionInstruction(renderingTool: self.renderingTool, timeRange: maxDuration!)]
    }

    func addVideoLayer(videoLayerSurface: VideoContentLayerSurface) async throws {
        let tracks = try await videoLayerSurface.asset.loadTracks(withMediaType: .video)
        let trackId = CMPersistentTrackID(renderingTool.layers.count)

        let scaleX = min(3.0, max(1.0 / (self.videoComposition.renderSize.width / videoLayerSurface.size.width), 0.0))
        let scaleY = min(3.0, max(1.0 / (self.videoComposition.renderSize.height / videoLayerSurface.size.height), 0.0))

        if
            let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: trackId),
            let track = tracks.first {
            compositionTrack.preferredTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)

            try compositionTrack.insertTimeRange(videoLayerSurface.timeRange, of: track, at: .zero)
            let layer = Layer(layer: videoLayerSurface)
            layer.transform = Transform(scale: .init(x: scaleX.float, y: scaleY.float))
            self.renderingTool.layers.append(layer)
        }
    }
}
