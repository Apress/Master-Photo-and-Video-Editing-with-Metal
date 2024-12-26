/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import simd
import SwiftUI

struct Vertex {
    var position: vector_float4
    var color: vector_float4

    init(position: vector_float4, color: vector_float4) {
        self.position = position
        self.color = color
    }

    init(x: CGFloat, y: CGFloat, color: Color) {
        self.init(position: vector_float4(Float(x), Float(y), 0, 1), color: color.vectorFloat4)
    }
}
