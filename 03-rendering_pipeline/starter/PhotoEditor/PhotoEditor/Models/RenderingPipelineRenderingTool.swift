/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import SwiftUI
import simd
import MetalKit

class RenderingPipelineRenderingTool: RenderingTool {
    private(set) var device: MTLDevice
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
    }
    
    func handleRenderEncoder(encoder: MTLRenderCommandEncoder, metalView mtkView: MTKView, viewportSize: CGSize) {
    }
}
