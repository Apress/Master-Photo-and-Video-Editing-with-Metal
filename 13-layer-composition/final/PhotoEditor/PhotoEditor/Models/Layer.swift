/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Accelerate
import CoreVideo
import Foundation
import MetalKit
import SwiftUI

// CHAPTER: transform
struct Transform {
    // Scale factor in range 0...1
    var scale: SIMD2<Float> = [1, 1]

    // Radians
    var rotation: Float = 0

    // Normalized Device Coordinate Offset
    var translation: SIMD2<Float> = [0, 0]

    static let identity = Transform()

    func makeMatrix(width: Int, height: Int) -> matrix_float4x4 {
        var transformedScale = scale
        if scale.x < 1.0, scale.y == 1.0 {
            transformedScale.x = scale.x / Float(width) * Float(height)
        }
        if scale.y < 1.0, scale.x == 1.0 {
            transformedScale.y = scale.y / Float(height) * Float(width)
        }
        let scaleMatrix = matrix_float4x4(diagonal: [
            transformedScale.x,
            transformedScale.y,
            1,
            1
        ])

        let cosRotation = cos(rotation)
        let sinRotation = sin(rotation)
        let rotationMatrix = matrix_float4x4(
            [cosRotation, sinRotation, 0, 0],
            [-sinRotation, cosRotation, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )

        let translationMatrix = matrix_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [translation.x, translation.y, 0, 1]
        )

        // Combine the transformations: first scale, then rotate, and finally translate
        // Yes, they are in opposite order
        return translationMatrix * rotationMatrix * scaleMatrix
    }
}

final class ContentLayerSurface {
    let backgroundImage: MTLTexture

    var target: MTLTexture

    init(device: MTLDevice, backgroundImage: URL) throws {
        self.backgroundImage = try MTKTextureLoader(device: device).newTexture(
            URL: backgroundImage,
            options: [.textureUsage: MTLTextureUsage.shaderRead.rawValue,
                      .textureStorageMode: MTLStorageMode.private.rawValue]
        )
        self.target = self.backgroundImage
    }
}

final class Layer: ObservableObject {
    let surface: ContentLayerSurface

    var opacity: Float = 1.0

    var transform: Transform = .identity

    init(layer: ContentLayerSurface) {
        self.surface = layer
        let imgWidth = surface.backgroundImage.width
        let imgHeight = surface.backgroundImage.height
        if imgWidth > imgHeight {
            transform.scale = SIMD2(
                x: 1.0,
                y: Float(imgHeight) / Float(imgWidth)
            )
        } else if imgHeight > imgWidth {
            transform.scale = SIMD2(
                x: Float(imgWidth) / Float(imgHeight),
                y: 1.0
            )
        }
    }
}
