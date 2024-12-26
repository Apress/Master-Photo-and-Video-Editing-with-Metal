/*
See the LICENSE.txt file for this sample’s licensing information.
*/
import Foundation
import SwiftUI
import simd

extension Color {
    static var secondarySystemBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        #error("Unsupported Platform")
        #endif
    }
    
    public init?(hex: String) {
        var hexInt: UInt64 = 0
        let scanner = Scanner(string: hex)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        scanner.scanHexInt64(&hexInt)

        let red = CGFloat((hexInt & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hexInt & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((hexInt & 0xFF) >> 0) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
    
    static var random: Color {
        return Color(red: .random(in: 0...1),
                     green: .random(in: 0...1),
                     blue: .random(in: 0...1))
    }
    
    var hexString: String {
        let (r, g, b, _) = rgbaCGFloat
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
    
    typealias RGBA<T: FloatingPoint> = (r: T, g: T, b: T, a: T)
        
    var rgbaCGFloat: RGBA<CGFloat> {
        var r: CGFloat = .zero
        var g: CGFloat = .zero
        var b: CGFloat = .zero
        var a: CGFloat = .zero
#if os(iOS)
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
#else
        NSColor(self).usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
#endif
        return (r, g, b, a)
    }
    
    init(rgb: simd_float3) {
        #if os(iOS)
            self.init(UIColor(red: rgb.x.cgFloat, green: rgb.y.cgFloat, blue: rgb.z.cgFloat, alpha: 1.0))
        #else
            self.init(NSColor(red: rgb.x.cgFloat, green: rgb.y.cgFloat, blue: rgb.z.cgFloat, alpha: 1.0))
        #endif
    }
    
    var rgbFloat3: simd_float3 {
        let (r,g,b,_) = rgbaDouble
        return simd_float3(r.float, g.float, b.float)
    }
    
    var rgbaDouble: RGBA<Double> {
        let (r,g,b,a) = rgbaCGFloat
        return (r.double, g.double, b.double, a.double)
    }
    
    var vectorFloat4: vector_float4 {
        let (r,g,b,a) = rgbaDouble
        return vector_float4(r.float, g.float, b.float, a.float)
    }
    
    var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = .zero
        var s: CGFloat = .zero
        var b: CGFloat = .zero
        var a: CGFloat = .zero
#if os(iOS)
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
#else
        NSColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
#endif
        return (h, s, b, a)
    }
    
    var mtlColor: MTLClearColor {
        let (r,g,b,a) = rgbaDouble
        return MTLClearColor(red: r, green: g, blue: b, alpha: a)
    }
}
