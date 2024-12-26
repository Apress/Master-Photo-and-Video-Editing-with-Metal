/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Foundation
import MetalKit

func layerRenderingToolWithTestData(device: any MTLDevice) -> LayerRenderingTool {
    let layerRenderingTool = try! LayerRenderingTool(device: device)

    let layer1 = Layer(layer: try! .init(device: device, sourceImage: Bundle.main.url(
        forResource: "example-0",
        withExtension: "jpg"
    )!))
    
    let layer2 = Layer(layer: try! .init(
        device: device,
        sourceImage: Bundle.main.url(
            forResource: "example-1",
            withExtension: "jpg"
        )!
    ));
    
    layer2.transform.scale *= 0.5

    layerRenderingTool.layers = [layer1, layer2]

    return layerRenderingTool
}
