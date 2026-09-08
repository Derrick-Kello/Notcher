import SwiftUI

struct SettingsView: View {
    private var settings: SettingsModel { AppEnvironment.shared.settings }
    
    var body: some View {
        @Bindable var settingsBindable = settings
        
        TabView {
            Form {
                Toggle("Enable Hover to Expand", isOn: $settingsBindable.configuration.hoverEnabled)
                Toggle("Pin by Default", isOn: $settingsBindable.configuration.pinnedByDefault)
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            
            Form {
                Section(header: Text("Dimensions")) {
                    Slider(value: $settingsBindable.configuration.collapsedWidth, in: 100...400) {
                        Text("Collapsed Width")
                    }
                    Slider(value: $settingsBindable.configuration.expandedWidth, in: 300...800) {
                        Text("Expanded Width")
                    }
                    Slider(value: $settingsBindable.configuration.expandedHeight, in: 100...400) {
                        Text("Expanded Height")
                    }
                    Slider(value: $settingsBindable.configuration.cornerRadius, in: 0...50) {
                        Text("Corner Radius")
                    }
                }
                
                Section(header: Text("Delays")) {
                    Slider(value: $settingsBindable.configuration.hoverDelay, in: 0...2) {
                        Text("Hover Delay")
                    }
                    Slider(value: $settingsBindable.configuration.collapseDelay, in: 0...5) {
                        Text("Collapse Delay")
                    }
                }
            }
            .padding()
            .tabItem {
                Label("Notch", systemImage: "rectangle.topthird.inset.filled")
            }
            
            Form {
                Text("Widgets configuration coming soon.")
            }
            .padding()
            .tabItem {
                Label("Widgets", systemImage: "square.grid.2x2")
            }
            
            Form {
                Toggle("Reduce Effects", isOn: $settingsBindable.configuration.reducedEffects)
            }
            .padding()
            .tabItem {
                Label("Appearance", systemImage: "paintpalette")
            }
        }
        .frame(width: 450, height: 350)
    }
}
