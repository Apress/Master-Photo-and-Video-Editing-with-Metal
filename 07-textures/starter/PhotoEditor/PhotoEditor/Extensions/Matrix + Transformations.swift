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
    
    init(perspective fovY: Float, aspect: Float, near: Float = 0.01, far: Float = 100) {
        let fovY = (fovY * 0.5).cgFloat.degreesToRadians().float
        let yScale = 1 / tan(fovY)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = far / zRange
        let wzScale = -near * far / zRange
        
        let X = SIMD4<Float>(xScale, 0, 0, 0)
        let Y = SIMD4<Float>(0, yScale, 0, 0)
        let Z = SIMD4<Float>(0, 0, zScale, 1)
        let W = SIMD4<Float>(0, 0, wzScale, 0)
        
        self.init(columns: (X, Y, Z, W))
    }
    
    init(cameraEyePosition eyePosition: simd_float3, targetPosition: simd_float3 = .init(.zero, .zero, .zero), upVector: simd_float3 = .init(0.0, 1.0, 0.0)) {
        let forwardVector = normalize(targetPosition - eyePosition)
        let rightVector = normalize(cross(upVector, forwardVector))
        let upVector = cross(forwardVector, rightVector)
        
        let X = SIMD4<Float>(rightVector.x, rightVector.y, rightVector.z, -dot(rightVector, eyePosition))
        let Y = SIMD4<Float>(upVector.x, upVector.y, upVector.z, -dot(upVector, eyePosition))
        let Z = SIMD4<Float>(forwardVector.x, forwardVector.y, forwardVector.z, -dot(forwardVector, eyePosition))
        let W = SIMD4<Float>(0, 0, 0, 1)
        
        self.init(columns: (X, Y, Z, W))
    }
}
