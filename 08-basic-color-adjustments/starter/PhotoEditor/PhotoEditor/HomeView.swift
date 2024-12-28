/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import SwiftUI
import MetalKit

struct HomeView: View {
    var body: some View {
        NavigationView {
            List {
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
