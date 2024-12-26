/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import MetalKit

func layerRenderingToolWithTestData(device: any MTLDevice) -> LayerRenderingTool {
    let layerRenderingTool = try! LayerRenderingTool(device: device)

    layerRenderingTool.layers.append(Layer(layer: try! .init(
        device: device,
        backgroundImage: Bundle.main.url(
            forResource: "example-0",

            withExtension: "jpg"
        )!
    )))
    layerRenderingTool.layers.last?.transform.scale = SIMD2(x: 1.0, y: 1.0)

    layerRenderingTool.layers.append(Layer(layer: try! .init(device: device, backgroundImage: Bundle.main.url(forResource: "example-1", withExtension: "jpg")!)))
    layerRenderingTool.layers.last?.transform.scale *= 0.5
    layerRenderingTool.layers.last?.transform.translation.x -= 0.5
    layerRenderingTool.layers.last?.transform.translation.y -= 0.5
    layerRenderingTool.layers.last?.opacity = 0.8


    layerRenderingTool.layers.append(Layer(layer: try! .init(device: device, backgroundImage: Bundle.main.url(forResource: "example-2", withExtension: "jpg")!)))
    layerRenderingTool.layers.last?.transform.scale *= 0.5
    layerRenderingTool.layers.last?.transform.translation.x += 0.5
    layerRenderingTool.layers.last?.transform.translation.y += 0.5
    layerRenderingTool.layers.last?.transform.rotation = 0.7

    layerRenderingTool.layers.append(Layer(layer: try! .init(
        device: device,
        backgroundImage: Bundle.main.url(
            forResource: "example-3",
            withExtension: "jpg"
        )!
    )))
    layerRenderingTool.layers.last?.transform.scale *= 0.9
    layerRenderingTool.layers.last?.transform.rotation = -0.2
    layerRenderingTool.layers.last?.opacity = 0.8

    layerRenderingTool.layers.append(Layer(layer: try! .init(
        device: device,
        backgroundImage: Bundle.main.url(
            forResource: "star",
            withExtension: "png"
        )!
    )))
    layerRenderingTool.layers.last?.transform.scale *= 0.1
    layerRenderingTool.layers.last?.transform.translation.x -= 0.1
    layerRenderingTool.layers.last?.transform.translation.y -= 0.1
    layerRenderingTool.layers.last?.opacity = 0.8

    layerRenderingTool.layers.append(Layer(layer: try! .init(device: device, backgroundImage: Bundle.main.url(forResource: "star", withExtension: "png")!)))
    layerRenderingTool.layers.last?.transform.scale *= 0.15
    layerRenderingTool.layers.last?.transform.translation.x += 0.05
    layerRenderingTool.layers.last?.transform.translation.y += 0.05
    layerRenderingTool.layers.last?.opacity = 0.7

    return layerRenderingTool
}
