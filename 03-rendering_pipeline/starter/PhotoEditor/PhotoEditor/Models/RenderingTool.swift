/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import MetalKit
import SwiftUI

protocol RenderingTool {
    var device: MTLDevice { get }
    
    func handleRenderEncoder(encoder: MTLRenderCommandEncoder, metalView mtkView: MTKView, viewportSize: CGSize)

}
