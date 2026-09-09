import SwiftUI

struct MenuBarView: View {
    private var stateMachine: NotchStateMachine { AppEnvironment.shared.stateMachine }
    private var settings: SettingsModel { AppEnvironment.shared.settings }
    
    var body: some View {
        VStack {
            Button(stateMachine.state == .expanded || stateMachine.state == .pinned ? "Collapse Notch" : "Expand Notch") {
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
            
            Menu("Themes") {
                ForEach(NotchTheme.allCases) { theme in
                    Button(action: {
                        settings.configuration.theme = theme
                    }) {
                        HStack {
                            if settings.configuration.theme == theme {
                                Image(systemName: "checkmark")
                            }
                            Text(theme.displayName)
                        }
                    }
                }
            }
            
            Button(action: {
                settings.configuration.lightingEffectEnabled.toggle()
            }) {
                HStack {
                    if settings.configuration.lightingEffectEnabled {
                        Image(systemName: "checkmark")
                    }
                    Text("Ambient Album Lighting")
                }
            }
            
            Divider()
            
            Button("Settings...") {
                SettingsWindowController.shared.showWindow()
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
