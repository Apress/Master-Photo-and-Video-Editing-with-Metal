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
    private var viewportSize: vector_uint2?

    // The command queue used to pass commands to the device.
    private var commandQueue: MTLCommandQueue?

    // The render pipeline generated from the vertex and fragment shaders in the .metal shader file.
    private var pipelineState: MTLRenderPipelineState?
 
    init(metalView mtkView: MTKView, renderingTool: RenderingTool) {
        mtkView.device = renderingTool.device
        mtkView.preferredFramesPerSecond = 120
        self.metalKitView = mtkView
        self.renderingTool = renderingTool
        self.device = renderingTool.device
        super.init()
                
        // Set MTKView background color to white
        metalKitView.clearColor = Color.white.mtlColor
        
        // Create the command queue
        commandQueue = renderingTool.device.makeCommandQueue()
        
        // Set MTKViewDelegate
        metalKitView.delegate = self
    }
    
    /// Called whenever view changes orientation or is resized
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Scale size with contentScaleFactor to fit viewPort into the bounds of DrawingView
        let size = size

        // Save the size of the drawable to pass to the vertex shader.
        viewportSize = vector_uint2(x: UInt32(size.width), y: UInt32(size.height))
    }

    /// Called whenever the view needs to render a frame.
    func draw(in view: MTKView) {
        guard
            // Create a new command buffer for each render pass to the current drawable.
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let viewportSize
        else { return }
        
        renderingTool.handleRenderEncoder(commandBuffer: commandBuffer, metalView: view, viewportSize: viewportSize)
        
        // Schedule a present once the framebuffer is complete using the current drawable.
        commandBuffer.present(view.currentDrawable!)
        
        // Finalize rendering here & push the command buffer to the GPU.
        commandBuffer.commit()
    }

}
