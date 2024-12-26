/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Foundation
import MetalKit

func layerRenderingToolWithTestData(device: any MTLDevice) -> LayerRenderingTool {
    let layerRenderingTool = try! LayerRenderingTool(device: device)

    layerRenderingTool.layers.append(Layer(layer: try! .init(device: device, backgroundImage: Bundle.main.url(
        forResource: "example-2",
        withExtension: "jpg"
    )!)))
    
    layerRenderingTool.layers.append(Layer(layer: try! .init(
        device: device,
        backgroundImage: Bundle.main.url(
            forResource: "gradient",
            withExtension: "jpg"
        )!
    )))

    return layerRenderingTool
}
