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
                Section(header: Text("Theme")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(NotchTheme.allCases) { theme in
                            let isSelected = settingsBindable.configuration.theme == theme
                            Button {
                                settingsBindable.configuration.theme = theme
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(theme.gradient(dynamicArtworkColor: nil))
                                        .frame(width: 18, height: 18)
                                    
                                    Text(theme.displayName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Effects & Lighting")) {
                    Toggle("Ambient Album Art Lighting", isOn: $settingsBindable.configuration.lightingEffectEnabled)
                    Text("Projects a soft color glow matching current album artwork behind the notch.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Reduce Effects", isOn: $settingsBindable.configuration.reducedEffects)
                }
            }
            .padding()
            .tabItem {
                Label("Appearance", systemImage: "paintpalette")
            }
        }
        .frame(width: 480, height: 380)
    }
}
