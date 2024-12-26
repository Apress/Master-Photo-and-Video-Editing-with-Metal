/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import CoreVideo
import Foundation
import MetalKit
import SwiftUI

public func makeWhiteTexture(device: MTLDevice) -> MTLTexture? {
    return makeColoredTexture(device: device, color: .white)
}

public func makeColoredTexture(device: MTLDevice, color: Color) -> MTLTexture? {
    return try? Texture(color: color, device: device, pixelFormat: .bgra8Unorm).texture
}

enum TextureError: Error {
    case couldNotCreate
}

class Texture {
    let texture: MTLTexture

    init(texture: MTLTexture) {
        self.texture = texture
    }
    
    init(color: Color, device: MTLDevice, pixelFormat: MTLPixelFormat = .bgra8Unorm,  width: Int? = nil, height: Int? = nil) throws {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width ?? 1, height: height ?? 1, mipmapped: false)
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw TextureError.couldNotCreate
        }
        let origin = MTLOrigin(x: 0, y: 0, z: 0)
        let tSize = MTLSize(width: texture.width, height: texture.height, depth: texture.depth)
        let region = MTLRegion(origin: origin, size: tSize)
        let mappedColor = simd_uchar4(color.vectorFloat4 * 255)
        [simd_uchar4](repeating: mappedColor, count: tSize.width * tSize.height).withUnsafeBytes { ptr in
            texture.replace(region: region, mipmapLevel: 0, withBytes: ptr.baseAddress!, bytesPerRow: tSize.width * 4)
        }
        self.texture = texture
    }
    
    init(device: MTLDevice, pixelFormat: MTLPixelFormat = .bgra8Unorm,  width: Int, height: Int) throws {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                                  width: width,
                                                                  height: height,
                                                                  mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        guard let texture = device.makeTexture(descriptor: descriptor) else { throw TextureError.couldNotCreate }
        self.texture = texture
    }

    init(pixelBuffer: CVPixelBuffer, device: MTLDevice, pixelFormat: MTLPixelFormat = .bgra8Unorm, width: Int? = nil, height: Int? = nil, plane: Int = 0) throws {
        guard let iosurface = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
            throw TextureError.couldNotCreate
        }

        let textureWidth: Int, textureHeight: Int
        if let width = width, let height = height {
            textureWidth = width
            textureHeight = height
        } else {
            textureWidth = CVPixelBufferGetWidth(pixelBuffer)
            textureHeight = CVPixelBufferGetHeight(pixelBuffer)
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                                  width: textureWidth,
                                                                  height: textureHeight,
                                                                  mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]

        guard
            let t = device.makeTexture(descriptor: descriptor,
                                       iosurface: iosurface,
                                       plane: plane)
        else { 
            throw TextureError.couldNotCreate
        }
        self.texture = t
    }
    
    var textureDescription: MTLTextureDescriptor {
        return MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: self.texture.pixelFormat,
            width: self.texture.width,
            height: self.texture.height,
            mipmapped: self.texture.mipmapLevelCount != 1
        )
    }
}

public extension MTLTexture {
    internal func bytes() -> UnsafeMutableRawPointer {
        let rowBytes = width * 4
        let bytes = malloc(width * height * 4)
        getBytes(bytes!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)

        return bytes!
    }

    func toImage() -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)

        let size = width * height * 4
        let rowBytes = width * 4
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) in
        }

        let bytes = bytes()
        let provider = CGDataProvider(dataInfo: nil, data: bytes, size: size, releaseData: releaseMaskImagePixelData)
        bytes.deallocate()
        
        let cgImageRef = CGImage(width: width,
                                 height: height,
                                 bitsPerComponent: 8,
                                 bitsPerPixel: 32,
                                 bytesPerRow: rowBytes,
                                 space: colorSpace,
                                 bitmapInfo: bitmapInfo,
                                 provider: provider!,
                                 decode: nil,
                                 shouldInterpolate: true,
                                 intent: CGColorRenderingIntent.defaultIntent)!

        return cgImageRef
    }
}
