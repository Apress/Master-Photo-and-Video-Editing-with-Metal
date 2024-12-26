/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import SwiftUI
import MetalKit

func makeView() -> MTKView {
    let view = MTKView()
    view.colorPixelFormat = .rgba8Unorm_srgb
    view.framebufferOnly = false
    return view
}

struct MetalView: View {
    @State private var metalView = makeView()
    @State private var renderer: Renderer?
    let renderingTool: RenderingTool
    
    var body: some View {
        MetalViewRepresentable(metalView: $metalView)
            .onAppear {
                renderer = Renderer(metalView: metalView, renderingTool: renderingTool)
                
            }
    }
}

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
#elseif os(iOS)
typealias ViewRepresentable = UIViewRepresentable
#endif

struct MetalViewRepresentable: ViewRepresentable {
    @Binding var metalView: MTKView
    
#if os(macOS)
    func makeNSView(context: Context) -> some NSView {
        metalView
    }
    func updateNSView(_ uiView: NSViewType, context: Context) {
        updateMetalView()
    }
#elseif os(iOS)
    func makeUIView(context: Context) -> MTKView {
        metalView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        updateMetalView()
    }
#endif
    
    func updateMetalView() {
        
        print("metal view size: \(self.metalView.frame.size) ")
    }
}
