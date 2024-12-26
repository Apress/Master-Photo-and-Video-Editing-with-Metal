/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import MetalKit

extension MTLPrimitiveType: CaseIterable, Identifiable {
    var label: String {
        switch self {
        case .point:
            return "Point"
        case .line:
            return "Line"
        case .lineStrip:
            return "Line Strip"
        case .triangle:
            return "Triangle"
        case .triangleStrip:
            return "Triangle Strip"
        @unknown default:
            return "Unknown"
        }
    }

    public var id: UInt {
        return self.rawValue
    }

    public static var allCases: [MTLPrimitiveType] {
        return [.triangle, .triangleStrip, .line, .lineStrip, .point]
    }
}
