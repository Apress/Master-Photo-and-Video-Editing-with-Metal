/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import SwiftUI

@main
struct ExamplesApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            true
        }
    }
#endif
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }.commands(content: {
            SidebarCommands()
        })
    }
}
