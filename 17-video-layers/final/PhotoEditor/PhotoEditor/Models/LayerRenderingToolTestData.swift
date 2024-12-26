/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Foundation
import MetalKit

func layerRenderingToolWithTestData(device: any MTLDevice) -> LayerRenderingTool {
    let layerRenderingTool = try! LayerRenderingTool(device: device)

    let sampleImgLayer = Layer(layer: try! ContentLayerSurface(device: device, backgroundImage: Bundle.main.url(
        forResource: "example-2",
        withExtension: "jpg"
    )!))
    sampleImgLayer.blendMode = .overlay
    sampleImgLayer.opacity = 0.9
    layerRenderingTool.layers.append(sampleImgLayer)

    let gradientLayer = Layer(layer: try! ContentLayerSurface(device: device, backgroundImage: Bundle.main.url(
        forResource: "gradient",
        withExtension: "jpg"
    )!))
    gradientLayer.blendMode = .multiply
    gradientLayer.opacity = 0.5
    layerRenderingTool.layers.append(gradientLayer)

    return layerRenderingTool
}
