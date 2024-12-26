/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import SwiftUI
struct HomeView: View {
    @State var selection: Int?

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: TransformationView(), tag: 0, selection: self.$selection) {
                    Text("Transformations").lineLimit(nil)
                }
            }.onAppear(perform: {
                if self.selection == nil {
                    self.selection = 0
                }
            })
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
