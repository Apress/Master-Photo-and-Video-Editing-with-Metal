/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import MetalKit
import SwiftUI

protocol RenderingTool {
    var device: MTLDevice { get }
    
    func handleRenderEncoder(commandBuffer: MTLCommandBuffer, metalView mtkView: MTKView, viewportSize: vector_uint2)
}
