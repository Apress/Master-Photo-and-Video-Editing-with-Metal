/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import AVFoundation
import AVKit
import Foundation
import MetalKit
import SwiftUI

struct EffectData: Identifiable, Hashable {
    let id: UUID = .init()
    var name: String
    var settingsView: FilterControlsView

    init(name: String, settingsView: FilterControlsView) {
        self.name = name
        self.settingsView = settingsView
    }

    static func == (lhs: EffectData, rhs: EffectData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class VideoEditorDataModel: ObservableObject {
    var device: MTLDevice = MTLCreateSystemDefaultDevice()!
    @Published var videoPlayer: AVPlayer?
    var renderingTool: VideoRenderingTool?
    var composition: VideoComposition?
    
    func effectsData(renderingTool: VideoRenderingTool) -> [EffectData] {
        return renderingTool.effects.compactMap { tooglableEffect in
            EffectData(name: tooglableEffect.effect.name, settingsView: tooglableEffect.makeSettingsView())
        }
    }

    func setAsset(_ asset: AVURLAsset) {
        self.videoPlayer = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        self.videoPlayer?.play()
    }
}

struct VideoEditorView: View {
    @ObservedObject var dataModel: VideoEditorDataModel

    var body: some View {
        Group {
            switch Result(catching: { () -> AVPlayer in
                if let videoPlayer = dataModel.videoPlayer {
                    return videoPlayer
                } else {
                    throw NSError(domain: "Video didn't load yet", code: 404)
                }
            }) {
            case let .success(videoPlayer):
                HStack {
                    Group {
                        VideoPlayer(player: videoPlayer)
                            .frame(minWidth: 400, minHeight: 400)
                            .inspector(isPresented: .constant(true)) {
                                if let renderingTool = dataModel.renderingTool {
                                    let effectsData = dataModel.effectsData(renderingTool: renderingTool)
                                    if !effectsData.isEmpty {
                                        EffectsInspectorView(effectsData: effectsData)
                                    }
                                }
                            }
                    }
                }
            case let .failure(error):
                Text(error.localizedDescription)
            }
        }.toolbar(content: {
            HStack(alignment: .top, spacing: 8.0, content: {
                Button("Load Sample Video") {
                    guard
                        let sampleVideoUrl = Bundle.main.url(forResource: "video-sample",
                                                             withExtension: "mp4")
                    else { return }
                    self.dataModel.setAsset(
                        AVURLAsset(url: sampleVideoUrl,
                                   options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
                    )
                }
                MediaPicker(title: "Choose Video", mediaType: .video, handler: { url in
                    self.dataModel.setAsset(
                        AVURLAsset(url: url,
                                   options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
                    )
                })
            })
        })
    }
}

struct EffectsInspectorView: View {
    let effectsData: [EffectData]

    var body: some View {
        List(effectsData) { effectData in
            effectData.settingsView
                .listRowInsets(EdgeInsets())
        }.padding(.horizontal, -8)
            .listStyle(.plain)
    }
}
