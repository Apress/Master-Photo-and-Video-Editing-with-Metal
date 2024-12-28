/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import CoreGraphics
import Foundation
import SwiftUI

extension CGImage {
    static func imageByName(_ named: String) -> CGImage? {
        #if os(iOS)
            return UIImage(named: named).cgImage
        #elseif os(macOS)
            return NSImage(named: named)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
            return nil
        #endif
    }
}
