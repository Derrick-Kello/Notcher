import SwiftUI

struct MenuBarView: View {
    private var stateMachine: NotchStateMachine { AppEnvironment.shared.stateMachine }
    
    var body: some View {
        VStack {
            Button("Toggle Notch") {
                stateMachine.send(.toggleRequested)
            }
            
            Button(stateMachine.state == .pinned ? "Unpin Notch" : "Pin Notch") {
                if stateMachine.state == .pinned {
                    stateMachine.send(.unpinRequested)
                } else {
                    stateMachine.send(.pinRequested)
                }
            }
            
            Divider()
            
            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button("About Notcher") {
                NSApp.orderFrontStandardAboutPanel(nil)
            }
            
            Button("Quit Notcher") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}
