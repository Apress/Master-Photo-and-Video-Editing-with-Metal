/*
See the LICENSE.txt file for this sample’s licensing information.
*/



import Foundation
import simd
import QuartzCore

extension matrix_float4x4 {
    
    init(scale s: CGPoint) {
        self.init([s.x.float, 0, 0, 0],
                  [0, s.y.float, 0, 0],
                  [0, 0, 1, 0],
                  [0, 0, 0, 1])
    }
    
    init(rotation r: simd_float3) {
        let xRotationMatrix = matrix_float4x4([1, 0, 0, 0],
                                              [0, r.x.cos, r.x.sin, 0],
                                              [0, -r.x.sin, r.x.cos, 0],
                                              [0, 0, 0, 1])
        
        let yRotationMatrix = matrix_float4x4([r.y.cos, 0, -r.y.sin, 0],
                                              [0, 1, 0, 0],
                                              [r.y.sin, 0, r.y.cos, 0],
                                              [0, 0, 0, 1])
        
        let zRotationMatrix = matrix_float4x4([r.z.cos, r.z.sin, 0, 0],
                                              [-r.z.sin, r.z.cos, 0, 0],
                                              [0, 0, 1, 0],
                                              [0, 0, 0, 1])

        self = xRotationMatrix * yRotationMatrix * zRotationMatrix
    }
    
    init(translation t: simd_float3) {
        self.init([1, 0, 0, 0],
                  [0, 1, 0, 0],
                  [0, 0, 1, 0],
                  [t.x, t.y, t.z, 1])
    }
    
    init(orthographicProjection rect: CGRect, near: Float, far: Float) {
        let left = -(rect.width / 2)
        let right = rect.width / 2
        let top = rect.height / 2
        let bottom = -(rect.height / 2)
        
        let sx = 2 / (right - left)
        let sy = 2 / (top - bottom)
        let sz = 1 / (near - far)
        let tx = (left + right) / (left - right)
        let ty = (top + bottom) / (bottom - top)
        let tz = near / (near - far)
        
        self.init([sx.float, 0, 0 , 0],
                  [0, sy.float, 0, 0],
                  [0, 0, sz, 0],
                  [tx.float, ty.float, tz, 1])
    }
    
    init(transform t: CATransform3D) {
        self.init([t.m11.float, t.m12.float, t.m13.float, t.m14.float],
                  [t.m21.float, t.m22.float, t.m23.float, t.m24.float],
                  [t.m31.float, t.m32.float, t.m33.float, t.m34.float],
                  [t.m41.float, t.m42.float, t.m43.float, t.m44.float])
    }
    
    init(double: matrix_double4x4) {
        self.init(double[0].float, double[1].float, double[2].float, double[3].float)
    }
}

extension CGAffineTransform {
    public func orientationMatrix() -> float4x4 {
        var orientation = matrix_identity_float4x4
        orientation[0][0] = Float(a)
        orientation[0][1] = Float(c)
        orientation[1][0] = Float(b)
        orientation[1][1] = Float(d)
        
        return orientation
    }
    
    public func normalizeOrientationMatrix() -> float4x4 {
        let transitionBeforeRotation = float4x4(translation: float3(-0.5, -0.5, 0))
        let orientation = orientationMatrix()
        let transitionAfterRotation = float4x4(translation: float3(0.5, 0.5, 0))
        
        return transitionAfterRotation * orientation * transitionBeforeRotation
    }
}
