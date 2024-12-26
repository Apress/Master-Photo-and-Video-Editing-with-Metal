/*
See the LICENSE.txt file for this sample’s licensing information.
*/



import Foundation
import MetalKit
import SwiftUI

public func makeWhiteTexture(device: MTLDevice) -> MTLTexture? {
    return makeColoredTexture(device: device, color: .white)
}

public func makeColoredTexture(device: MTLDevice, color: Color) -> MTLTexture? {
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb, width: 1, height: 1, mipmapped: false)
    guard let texture = device.makeTexture(descriptor: textureDescriptor) else { return nil }
    let origin = MTLOrigin(x: 0, y: 0, z: 0)
    let tSize = MTLSize(width: texture.width, height: texture.height, depth: texture.depth)
    let region = MTLRegion(origin: origin, size: tSize)
    let mappedColor = simd_uchar4(color.vectorFloat4 * 255)
    Array<simd_uchar4>(repeating: mappedColor, count: tSize.width * tSize.height).withUnsafeBytes { ptr in
        texture.replace(region: region, mipmapLevel: 0, withBytes: ptr.baseAddress!, bytesPerRow: tSize.width * 4)
    }
    return texture
}

extension MTLTexture {
    
    func cgImage(bpr: Int) -> CGImage? {
        let length = bpr * self.height
        
        let pixelBytes = UnsafeMutableRawPointer.allocate(byteCount: length,
                                                          alignment: MemoryLayout<UInt8>.alignment)
        defer { pixelBytes.deallocate() }
        
        let destinationRegion = MTLRegion(origin: .init(x: 0, y: 0, z: 0),
                                          size: .init(width: self.width,
                                                      height: self.height,
                                                      depth: self.depth))
        self.getBytes(pixelBytes,
                         bytesPerRow: bpr,
                         from: destinationRegion,
                         mipmapLevel: 0)
        
        let colorScape = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        guard let data = CFDataCreate(nil,
                                      pixelBytes.assumingMemoryBound(to: UInt8.self),
                                      length),
              let dataProvider = CGDataProvider(data: data),
              let cgImage = CGImage(width: self.width,
                                    height: self.height,
                                    bitsPerComponent: 8,
                                    bitsPerPixel: 32,
                                    bytesPerRow: bpr,
                                    space: colorScape,
                                    bitmapInfo: bitmapInfo,
                                    provider: dataProvider,
                                    decode: nil,
                                    shouldInterpolate: true,
                                    intent: .defaultIntent)
        else { return nil }
        return cgImage
    }
    
}
