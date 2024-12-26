/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Accelerate
import CoreVideo
import Foundation
import MetalKit
import SwiftUI

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

final class TogglableEffect {
    let effect: EffectPass
    var isEnabled: Bool = false
    
    init(effect: EffectPass) {
        self.effect = effect
    }
    
    func makeSettingsView() -> FilterControlsView {
        var view = FilterControlsView(name: self.effect.name, parameters: self.effect.parameters)
        view.makeTogglable(enabled: self.isEnabled, callback: { self.isEnabled = $0 })
        return view
    }
}

final class ContentLayerSurface {
    let source: MTLTexture

    var texture: MTLTexture
    
    var effects: [TogglableEffect]

    init(device: MTLDevice, sourceImage: URL) throws {
        self.source = try MTKTextureLoader(device: device).newTexture(
            URL: sourceImage,
            options: [
                .textureUsage: MTLTextureUsage.shaderRead.rawValue,
                .textureStorageMode: MTLStorageMode.private.rawValue
            ]
        )

        let targetDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: self.source.pixelFormat,
            width: self.source.width,
            height: self.source.height,
            mipmapped: false
        )
        
        targetDesc.usage = [.shaderRead, .renderTarget, .shaderWrite]
        targetDesc.storageMode  = .private

        self.texture = device.makeTexture(descriptor: targetDesc)!
        
        var availableEffects: [any EffectPass] = []
        
        do {
            availableEffects = [
                try GaussianBlurEffect(device: device),
                try ContrastBrightnessSaturationEffect(device: device),
                try VignetteEffect(device: device),
                try LutColorCorrectionEffect(device: device),
                try TwirlEffect(device: device)
            ]
        } catch {
            print("error of effects initalizing: \(error)")
        }

        self.effects = availableEffects.map { TogglableEffect(effect: $0) }
    }
    
    func render(cb: MTLCommandBuffer) {
        // Copy background image to our target
        if let blitEncoder = cb.makeBlitCommandEncoder() {
            blitEncoder.copy(from: self.source, to: self.texture)
            blitEncoder.endEncoding()
        }
        
        let enabledEffects = self.effects.filter({ $0.isEnabled })
                    
        for effect in enabledEffects {
            effect.effect.writeCommands(cb: cb, target: self.texture)
        }
    }
}

final class Layer: ObservableObject {
    let surface: ContentLayerSurface

    var blendMode: BlendMode = .normal
    var opacity: Float = 1.0

    var transform: Transform = .identity

    init(layer: ContentLayerSurface) {
        self.surface = layer
        let imgWidth = surface.texture.width
        let imgHeight = surface.texture.height
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
