/*
See the LICENSE.txt file for this sample’s licensing information.
*/



import Foundation
import MetalKit
import SwiftUI
import Combine

protocol EffectPass {
    /// Name of the effect.
    var name: String { get }
    
    /// Record commands into command buffer for the effect.
    ///
    /// @param target Texture to read input from and write output to.
    func writeCommands(cb: MTLCommandBuffer, target: MTLTexture)
    
    /// SwiftUI view to control effect's settings
    var parameters: [any FilterParamaters] { get }
}
