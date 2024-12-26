/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import MetalKit
import SwiftUI

struct ProjectionTransformationView: View {
    @StateObject private var renderingTool = ProjectionTransformationRenderingTool()

    var body: some View {
        VStack {
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
                        Text("Aspect \(renderingTool.aspect, specifier: "%.2f")")
                        Slider(value: $renderingTool.aspect, in: 0.0 ... 5.0)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.secondarySystemBackground)
                    )
                }.frame(height: 200)
            }
        }.toolbar(content: { Spacer() })
            .inlineNavigationBarTitle("Perspective Transformations")
    }

    private var primitivePickerLabel: String {
        #if os(iOS)
            return renderingTool.primitiveType.label.localizedCapitalized
        #else
            return "Primitive Type"
        #endif
    }
}

#Preview {
    ProjectionTransformationView()
}
