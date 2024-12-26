/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import Foundation
import simd

extension CGPoint {
    func interpolate(to: CGPoint, progress: CGFloat) -> CGPoint {
        guard progress >= 0.0 && progress <= 1.0 else { return self }
        let x = self.x.interpolate(to: to.x, progress: progress)
        let y = self.y.interpolate(to: to.y, progress: progress)
        return CGPoint(x: x, y: y)
    }
    
    init(vector: vector_uint2) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
    
    init(vector: vector_float2) {
        self.init(x: vector.x.cgFloat, y: vector.y.cgFloat)
    }
    
    var vectorFloat: vector_float2 {
        return vector_float2(x: x.float, y: y.float)
    }
    
    var vectorUint: vector_uint2 {
        return vector_uint2(x: x.int32, y: y.int32)
    }
    
    func angleToPoint(pointOnCircle: CGPoint) -> CGFloat {
        let originX = pointOnCircle.x - self.x
        let originY = pointOnCircle.y - self.y
        var radians = atan2(originY, originX)
        while radians < 0 {
            radians += CGFloat(2 * Double.pi)
        }
        
        return radians
    }
    
    // Arithmetic

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func -(lhs: CGPoint, rhs: CGPoint) -> CGVector {
        return CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }

    static func -(lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func *(lhs: CGFloat, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: rhs.x * lhs, y: rhs.y * lhs)
    }
    
    func distanceToPoint(otherPoint: CGPoint) -> CGFloat {
        return sqrt(pow((otherPoint.x - x), 2) + pow((otherPoint.y - y), 2))
    }
}
