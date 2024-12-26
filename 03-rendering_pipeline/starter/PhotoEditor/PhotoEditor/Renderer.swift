/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import MetalKit
import SwiftUI

class Renderer: NSObject, MTKViewDelegate {
    
    private var device: MTLDevice
    private var metalKitView: MTKView
    private var renderingTool: RenderingTool

    // The current size of the view, used as an input to the vertex shader.
    private var viewportSize: CGSize

    // The command queue used to pass commands to the device.
    private var commandQueue: MTLCommandQueue?

    init(metalView mtkView: MTKView, renderingTool: RenderingTool) {
        self.device = MTLCreateSystemDefaultDevice()!
        mtkView.device = self.device
        mtkView.preferredFramesPerSecond = 120
        self.metalKitView = mtkView
        self.viewportSize = mtkView.drawableSize
        self.renderingTool = renderingTool
        self.device = renderingTool.device
        super.init()
        
        // Set MTKView background color to white
        metalKitView.clearColor = Color.white.mtlColor
        
        // Create the command queue
        commandQueue = device.makeCommandQueue()
        
        // Set MTKViewDelegate
        metalKitView.delegate = self
    }
    
    /// Called whenever view changes orientation or is resized
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Save the size of the drawable to pass to the vertex shader.
        viewportSize = size
    }
    
    /// Called whenever the view needs to render a frame.
    func draw(in view: MTKView) {
        guard
            // Create a new command buffer for each render pass to the current drawable.
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            // Obtain a renderPassDescriptor generated from the view's drawable textures
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            // Create a render command encoder.
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }
        
        // Set the region of the drawable to draw into.
        renderEncoder.setViewport(MTLViewport(
            originX: .zero,
            originY: .zero,
            width: Double(viewportSize.width),
            height: Double(viewportSize.height),
            znear: .zero,
            zfar: 1.0
        ))
        
        if ((Date().timeIntervalSince1970 * 1000).int % 95 == .zero) {
            // Generate random background color.
            metalKitView.clearColor = Color.random.mtlColor
        }
        
        renderEncoder.endEncoding()
        
        // Schedule a present once the framebuffer is complete using the current drawable.
        commandBuffer.present(view.currentDrawable!)
        
        // Finalize rendering here & push the command buffer to the GPU.
        commandBuffer.commit()
    }
    
}
