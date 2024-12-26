/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import SwiftUI
struct HomeView: View {
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: FundamentalsView()) {
                    Text("Fundamentals")
                }
                NavigationLink(destination: RenderingPipelineView()) {
                    Text("Rendering Pipeline")
                }
                NavigationLink(destination: PrimitiveTypesView()) {
                    Text("Primitive Types")
                }
                NavigationLink(destination: PointPrimitiveTypesView()) {
                    Text("Point Primitive Type")
                }
                NavigationLink(destination: LinePrimitiveTypesView()) {
                    Text("Line Primitive Type")
                }
            }
            .groupedListStyle()
            .inlineNavigationBarTitle("Photo Editor")
            
            VStack(spacing: 6) {
                Text("Welcome to Examples App.")
                Text("Select a topic to begin.").font(Font.caption).foregroundColor(.secondary)
            }.toolbar(content: { Spacer() })
        }
        .stackNavigationViewStyle()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
