/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Foundation
import SwiftUI

struct FundamentalsView: View {
    var body: some View {
        VStack {
            MetalView()
        }.toolbar(content: { Spacer() })
            .inlineNavigationBarTitle("Photo Editor")
    }
}

struct FundamentalsView_Previews: PreviewProvider {
    static var previews: some View {
        FundamentalsView()
    }
}
