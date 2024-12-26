/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import SwiftUI

struct RenderingPipelineView: View {
    var body: some View {
      VStack {
        MetalView(renderingTool: RenderingPipelineRenderingTool())
      }.toolbar(content: { Spacer() })
          .inlineNavigationBarTitle("Photo Editor")
    }
}

#Preview {
    RenderingPipelineView()
}
