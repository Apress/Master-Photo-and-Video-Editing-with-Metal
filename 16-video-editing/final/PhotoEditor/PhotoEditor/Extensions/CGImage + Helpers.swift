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
        #endif
        return nil
    }    
    
    public func pixelBuffer(width: Int, height: Int,
                            pixelFormatType: OSType,
                            colorSpace: CGColorSpace,
                            alphaInfo: CGImageAlphaInfo,
                            orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        
      var maybePixelBuffer: CVPixelBuffer?
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                   kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
      let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       width,
                                       height,
                                       pixelFormatType,
                                       attrs as CFDictionary,
                                       &maybePixelBuffer)

      guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
        return nil
      }

      let flags = CVPixelBufferLockFlags(rawValue: 0)
      guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
        return nil
      }
      defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }

      guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                    space: colorSpace,
                                    bitmapInfo: alphaInfo.rawValue)
      else {
        return nil
      }

      context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
      return pixelBuffer
    }
}
