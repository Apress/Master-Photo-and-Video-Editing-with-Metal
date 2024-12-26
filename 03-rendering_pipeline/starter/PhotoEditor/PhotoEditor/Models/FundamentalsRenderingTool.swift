/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import simd
import SwiftUI
import MetalKit

class FundamentalsRenderingTool: RenderingTool {
    private(set) var device: MTLDevice
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
    }
    
    func handleRenderEncoder(encoder: MTLRenderCommandEncoder, metalView mtkView: MTKView, viewportSize: CGSize) {
        // Set the region of the drawable to draw into.
        encoder.setViewport(MTLViewport(
            originX: .zero,
            originY: .zero,
            width: Double(viewportSize.width),
            height: Double(viewportSize.height),
            znear: .zero,
            zfar: 1.0
        ))
        
        if ((Date().timeIntervalSince1970 * 1000).int % 95 == .zero) {
            // Generate a random background color.
            mtkView.clearColor = Color.random.mtlColor
        }
    }
}
