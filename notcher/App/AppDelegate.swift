import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: NotchWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Get the shared environment from the SwiftUI app
        let environment = AppEnvironment.shared
        
        // Create and show the notch window
        windowController = NotchWindowController(environment: environment)
        windowController?.show()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        windowController?.hide()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Menu bar app stays running
    }
}
