import SwiftUI

@main
struct NotcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Notcher", systemImage: "rectangle.topthird.inset.filled") {
            MenuBarView()
        }
        
        Settings {
            SettingsView()
        }
    }
}
