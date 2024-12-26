/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import simd
import SwiftUI

struct TextureVertex {
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    var position: vector_float2
    var texcoord: vector_float2
    
    init(position: vector_float2, texcoord: vector_float2) {
        self.position = position
        self.texcoord = texcoord
    }
    
    init(corner: Corner) {
        switch corner {
        case .topLeft:
            self.init(position: .init(x: -1.0, y: 1.0), texcoord: .init(0.0, 0.0))
        case .topRight:
            self.init(position: .init(x: 1.0, y: 1.0), texcoord: .init(1.0, 0.0))
        case .bottomLeft:
            self.init(position: .init(x: -1, y: -1), texcoord: .init(0.0, 1.0))
        case .bottomRight:
            self.init(position: .init(x: 1, y: -1), texcoord: .init(1.0, 1.0))
        }
    }
}
