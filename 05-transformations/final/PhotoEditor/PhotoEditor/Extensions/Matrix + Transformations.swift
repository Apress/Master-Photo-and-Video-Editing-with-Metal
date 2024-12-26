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
}
