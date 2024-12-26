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

// Collection of render pipelines we use for blending layers together.
struct BlendingPipelines {
    let normal: MTLRenderPipelineState
    let multiply: MTLRenderPipelineState
    let screen: MTLRenderPipelineState
    let overlay: MTLRenderPipelineState
    let hardLight: MTLRenderPipelineState
    let softLight: MTLRenderPipelineState
    let colorBurn: MTLRenderPipelineState
    let darken: MTLRenderPipelineState
    let lighten: MTLRenderPipelineState
    let difference: MTLRenderPipelineState
    let subtract: MTLRenderPipelineState
    
    init(device: MTLDevice) {
        self.normal = makeBlendingPipeline(device: device, fragmentName: "layerNormalBlendFS")
        self.multiply = makeBlendingPipeline(device: device, fragmentName: "layerMultiplyBlendFS")
        self.screen = makeBlendingPipeline(device: device, fragmentName: "layerScreenBlendFS")
        self.overlay = makeBlendingPipeline(device: device, fragmentName: "layerOverlayBlendFS")
        self.hardLight = makeBlendingPipeline(device: device, fragmentName: "layerHardLightBlendFS")
        self.softLight = makeBlendingPipeline(device: device, fragmentName: "layerSoftLightBlendFS")
        self.colorBurn = makeBlendingPipeline(device: device, fragmentName: "layerColorBurnBlendFS")
        self.darken = makeBlendingPipeline(device: device, fragmentName: "layerDarkenBlendFS")
        self.lighten = makeBlendingPipeline(device: device, fragmentName: "layerLightenBlendFS")
        self.difference = makeBlendingPipeline(device: device, fragmentName: "layerDifferenceBlendFS")
        self.subtract = makeBlendingPipeline(device: device, fragmentName: "layerSubtractBlendFS")
    }
    
    func getPipeline(for blendMode: BlendMode) -> MTLRenderPipelineState {
        switch blendMode {
        case .normal:
            return self.normal
        case .multiply:
            return self.multiply
        case .screen:
            return self.screen
        case .overlay:
            return self.overlay
        case .hardLight:
            return self.hardLight
        case .softLight:
            return self.softLight
        case .colorBurn:
            return self.colorBurn
        case .darken:
            return self.darken
        case .lighten:
            return self.lighten
        case .difference:
            return self.difference
        case .subtract:
            return self.subtract
        }
    }
}

fileprivate func makeBlendingPipeline(device: MTLDevice, fragmentName: String) -> MTLRenderPipelineState {
    let library = device.makeDefaultLibrary()!
    let vertexFunction = library.makeFunction(name: "layerVS")
    let fragmentFunction = library.makeFunction(name: fragmentName)

    let descriptor = MTLRenderPipelineDescriptor()

    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction

    descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm_srgb
    descriptor.colorAttachments[0].isBlendingEnabled = false

    let pipeline = try! device.makeRenderPipelineState(descriptor: descriptor)

    return pipeline
}

enum BlendMode: String, CaseIterable {
    case normal
    case multiply
    case screen
    case overlay
    case hardLight
    case softLight
    case colorBurn
    case darken
    case lighten
    case difference
    case subtract
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

    var blendMode: BlendMode = .normal
    var opacity: Float = 1.0

    var transform: Transform = .identity

    init(layer: ContentLayerSurface) {
        self.surface = layer
        let imgWidth = surface.backgroundImage.width
        let imgHeight = surface.backgroundImage.height
        if imgWidth > imgHeight {
            transform.scale = SIMD2(
                x: Float(imgWidth) / Float(imgHeight),
                y: 1.0
            )
        } else if imgHeight > imgWidth {
            transform.scale = SIMD2(
                x: 1.0,
                y: Float(imgHeight) / Float(imgWidth)
            )
        }
    }
}