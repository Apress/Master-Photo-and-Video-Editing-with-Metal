/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Foundation
import MetalKit
import SwiftUI

struct TransformationView: View {
    @StateObject private var renderingTool = TransformationRenderingTool()

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                MetalView(renderingTool: renderingTool)
                VStack(alignment: .leading, spacing: 4.0) {
                    Text("Scale \(renderingTool.scaleTransform, specifier: "%.2f")")
                    Slider(value: $renderingTool.scaleTransform, in: 0.5 ... 2.0)
                    Text("Rotation \(renderingTool.rotationTransform, specifier: "%.2f")")
                    Slider(value: $renderingTool.rotationTransform, in: 0.0 ... 360.0)
                    Text("Translate x \(renderingTool.translateTransformX, specifier: "%.2f")")
                    Slider(value: $renderingTool.translateTransformX, in: -1.0 ... 1.0)
                    Text("Translate y \(renderingTool.translateTransformY, specifier: "%.2f")")
                    Slider(value: $renderingTool.translateTransformY, in: -1.0 ... 1.0)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color.secondarySystemBackground)
                )
            }.padding()
        }.toolbar(content: { Spacer() })
            .inlineNavigationBarTitle("Coordinate Space And Shader Functions")
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
    TransformationView()
}
