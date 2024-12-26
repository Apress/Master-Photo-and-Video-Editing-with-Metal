/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import AVFoundation
import AVKit
import Foundation
import MetalKit
import SwiftUI

struct LayerData: Identifiable, Hashable {
    var id: Int
    var transform: Transform
    var blendMode: String
    var effects: [EffectData]
    var opacity: Float
    var isVideo: Bool

    static func == (lhs: LayerData, rhs: LayerData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

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
    @Published var selectedIndex: Int = 0
    @Published var videoPlayer: AVPlayer?
    var renderingTool: LayerRenderingTool

    init() {
        self.renderingTool = try! LayerRenderingTool(device: device)
    }

    func layersData() -> [LayerData] {
        return renderingTool.layers.enumerated().compactMap { index, layer in
            let transformParameters: [any FilterParamaters] = [SliderParameters(
                binding: .init(
                    get: { layer.transform.scale.x },
                    set: { layer.transform.scale = SIMD2(
                        $0, layer.transform.scale.y
                    ) }
                ),
                name: "Scale X",
                step: 0.1,
                range: 0 ... 5,
                value: layer.transform.scale.x
            ),
            SliderParameters(
                binding: .init(
                    get: { layer.transform.scale.y },
                    set: { layer.transform.scale = SIMD2(
                        layer.transform.scale.x, $0
                    ) }
                ),
                name: "Scale Y",
                step: 0.1,
                range: 0 ... 5,
                value: layer.transform.scale.y
            ),
            SliderParameters(
                binding: .init(
                    get: { layer.transform.translation.x },

                    set: { layer.transform.translation.x = $0 }
                ),
                name: "Translate X",
                step: 0.01,
                range: -2.0 ... 2.0,
                value: layer.transform.translation.x
            ),

            SliderParameters(
                binding: .init(
                    get: { -layer.transform.translation.y },

                    set: { layer.transform.translation.y = -$0 }
                ),
                name: "Translate Y",
                step: 0.01,
                range: -2.0 ... 2.0,
                value: layer.transform.translation.y
            ),

            SliderParameters(
                binding: .init(
                    get: { layer.transform.rotation },
                    set: { layer.transform.rotation = $0 }
                ),
                name: "Rotation",
                step: 0.01,
                range: -1.0 ... 1.0,
                value: layer.transform.rotation
            )]

            let blendModeParams: [any FilterParamaters] = [SliderParameters(
                binding: .init(
                    get: { layer.opacity },
                    set: { layer.opacity = $0 }
                ),
                name: "Opacity",
                step: 0.01,
                range: 0 ... 1,
                value: layer.opacity
            ),
            PickerParameters(
                binding: .init(
                    get: { layer.blendMode.rawValue },
                    set: { layer.blendMode = BlendMode(rawValue: $0)! }
                ),
                name: "Blend Mode",
                value: layer.blendMode.rawValue,
                values: BlendMode.allCases.map { $0.rawValue }
            )]

            let transformEffectData = EffectData(
                name: "Transform",
                settingsView: FilterControlsView(
                    name: "Transform",
                    parameters: transformParameters
                )
            )

            let blendModeEffectData = EffectData(
                name: "Blend Mode",
                settingsView: FilterControlsView(
                    name: "Content Layer",
                    parameters: blendModeParams
                )
            )

            let effectDatas = [blendModeEffectData, transformEffectData] + layer.surface.effects.compactMap { EffectData(name: $0.effect.name, settingsView: $0.makeSettingsView()) }

            return LayerData(
                id: index,
                transform: layer.transform,
                blendMode: "normal",
                effects: effectDatas,
                opacity: layer.opacity,
                isVideo: layer.surface is VideoContentLayerSurface
            )
        }
    }

    var composition: VideoComposition?

    func addLayer(selectedImageUrl: URL?) {
        if let selectedImageUrl {
            do {
                let surface = try ContentLayerSurface(device: self.device, backgroundImage: selectedImageUrl)
                let layer = Layer(layer: surface)
                self.renderingTool.layers.append(layer)
            } catch {
                print(error)
            }
        }
        selectedIndex = layersData().count - 1
    }

    func setAsset(_ asset: AVURLAsset) {
        Task.init {
            do {
                if self.composition == nil {
                    self.composition = try await VideoComposition(renderingTool: renderingTool, asset: asset)
                } else {
                    try await self.composition?.addVideoTrack(asset: asset)
                }

                guard let src = self.composition else { return }
                let videoComposition = await src.videoComposition
                let composition = await src.composition

                let playerItem = AVPlayerItem(asset: composition)
                playerItem.videoComposition = videoComposition

                await MainActor.run {
                    selectedIndex = layersData().count - 1
                    self.videoPlayer = AVPlayer(playerItem: playerItem)
                    self.videoPlayer?.play()
                }
            } catch {
                print("texture loading error: \(error)")
            }
        }
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
                    NavigationStack {
                        if !dataModel.layersData().isEmpty {
                            List(dataModel.layersData(), id: \.self, selection: .init(get: {
                                dataModel.layersData()[dataModel.selectedIndex]
                            }, set: { dataModel.selectedIndex = dataModel.layersData().firstIndex(of: $0) ?? 0 })) { layerData in
                                Text("\(layerData.isVideo ? "Video Layer" : "Image Layer") \(layerData.id)")
                            }.navigationTitle("Layers")
                        } else {
                            EmptyView().navigationTitle("Layers")
                        }
                    }
                    .frame(width: 250)
                    Group {
                        VideoPlayer(player: videoPlayer)
                            .frame(minWidth: 400, minHeight: 400)
                            .inspector(isPresented: .constant(true)) {
                                if !dataModel.layersData().isEmpty {
                                    let selectedLayer = dataModel.layersData()[dataModel.selectedIndex]
                                    LayerEffectsInspectorView(layerData: selectedLayer)
                                }
                            }
                    }
                }
            case let .failure(error):
                Text(error.localizedDescription)
            }
        }.toolbar(content: {
            HStack(alignment: .top, spacing: 8.0, content: {
                MediaPicker(title: "Add Layer With Image", mediaType: .image, handler: { url in
                    self.dataModel.addLayer(selectedImageUrl: url)
                })
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
                    print("choosen video at url: \(url)")
                    self.dataModel.setAsset(
                        AVURLAsset(url: url,
                                   options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
                    )
                })
            })
        })
    }
}

struct LayerEffectsInspectorView: View {
    let layerData: LayerData

    var body: some View {
        List(layerData.effects) { effectData in
            effectData.settingsView
                .listRowInsets(EdgeInsets())
        }.padding(.horizontal, -8)
            .listStyle(.plain)
    }
}
