/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import SwiftUI
import MetalKit

struct HomeView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: contrastBrightnessSaturationAdjustmentsEffectsView()) {
                    Text("Contrast, brightness, saturation")
                }
                NavigationLink(destination: vignetteEffectsView()) {
                    Text("Vignette")
                }
            }
            .groupedListStyle()
            
            VStack(spacing: 6) {
                Text("Welcome to Examples App.")
                Text("Select a topic to begin.").font(Font.caption).foregroundColor(.secondary)
            }.toolbar(content: { Spacer() })
        }
        .stackNavigationViewStyle()
    }
}

func contrastBrightnessSaturationAdjustmentsEffectsView() -> EffectsView {
    let device = MTLCreateSystemDefaultDevice()!
    let effects = [try! ContrastBrightnessSaturationEffect(device: device)]
    return EffectsView(device: device, effects: effects)
}

func vignetteEffectsView() -> EffectsView {
    let device = MTLCreateSystemDefaultDevice()!
    let effects = [try! VignetteEffect(device: device)]
    return EffectsView(device: device, effects: effects)
}
