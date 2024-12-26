/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Foundation
import MetalKit
import SwiftUI

struct TextureProjectionTransformationView: View {
    let device = MTLCreateSystemDefaultDevice()!
    @StateObject var renderingTool = TextureProjectionTransformationRenderingTool()

    var body: some View {
        Group {
            VStack(alignment: .leading) {
                MetalView(renderingTool: renderingTool)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4.0) {
                        Text("FOV (Field-of-View) \(renderingTool.fov, specifier: "%f")")
                        Slider(value: $renderingTool.fov, in: 15.0 ... 180.0)
                        Text("Translation Z \(renderingTool.translationZ, specifier: "%.2f")")
                        Slider(value: $renderingTool.translationZ, in: -20.0 ... 20.0)
                        Text("Rotation Y \(renderingTool.rotationY, specifier: "%.2f")")
                        Slider(value: $renderingTool.rotationY, in: -20.0 ... 20.0)
                        Text("Eye Position X \(renderingTool.eyePosition.x, specifier: "%.2f")")
                        Slider(value: $renderingTool.eyePosition.x, in: -20.0 ... 20.0)
                        Text("Eye Position Y \(renderingTool.eyePosition.y, specifier: "%.2f")")
                        Slider(value: $renderingTool.eyePosition.y, in: -20.0 ... 20.0)
                        Text("aspect \(renderingTool.aspect, specifier: "%.2f")")
                        Slider(value: $renderingTool.aspect, in: -10.0 ... 10.0)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.secondarySystemBackground)
                    )
                }.frame(height: 200)
            }.padding()
        }.toolbar(content: {
            ImagePicker(title: "Choose Image", handler: { url in
                print("image selected at url: \(url)")
                do {
                    let texture = try MTKTextureLoader(device: device).newTexture(URL: url)
                    texture.label = "selected_image"
                    self.renderingTool.update(texture: texture)
                } catch {
                    print("texture loading error: \(error)")
                }
            })
        })
    }
}

#Preview {
    TextureProjectionTransformationView()
}
