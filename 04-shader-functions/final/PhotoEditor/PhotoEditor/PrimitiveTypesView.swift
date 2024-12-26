/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import SwiftUI

struct PrimitiveTypesView: View {
    var body: some View {
      VStack {
          MetalView(renderingTool: PrimitiveTypesRenderingPipelineTool(selectedPrimitiveType: .triangle))
      }.toolbar(content: { Spacer() })
          .inlineNavigationBarTitle("Photo Editor")
    }
}

struct PointPrimitiveTypesView: View {
    var body: some View {
      VStack {
          MetalView(renderingTool: PrimitiveTypesRenderingPipelineTool(selectedPrimitiveType: .point))
      }.toolbar(content: { Spacer() })
          .inlineNavigationBarTitle("Photo Editor")
    }
}

struct LinePrimitiveTypesView: View {
    var body: some View {
      VStack {
          MetalView(renderingTool: PrimitiveTypesRenderingPipelineTool(selectedPrimitiveType: .line))
      }.toolbar(content: { Spacer() })
          .inlineNavigationBarTitle("Photo Editor")
    }
}
