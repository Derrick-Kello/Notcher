//
//  SettingsView.swift
//  notcher
//

import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case notch = "Notch"
    case appearance = "Appearance"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .notch: return "rectangle.topthird.inset.filled"
        case .appearance: return "paintpalette"
        }
    }
}

struct SettingsView: View {
    @State private var settings = AppEnvironment.shared.settings
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        @Bindable var settingsBindable = settings
        
        VStack(spacing: 0) {
            // Header / Tab Selector
            HStack(spacing: 12) {
                ForEach(SettingsTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            selectedTab == tab
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                        .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .general:
                        generalSection(settingsBindable: $settingsBindable)
                    case .notch:
                        notchSection(settingsBindable: $settingsBindable)
                    case .appearance:
                        appearanceSection(settingsBindable: $settingsBindable)
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Bottom Toolbar
            HStack {
                Button("Reset to Defaults") {
                    settings.resetToDefaults()
                }
                .buttonStyle(BorderedButtonStyle())
                
                Spacer()
                
                Button("Done") {
                    SettingsWindowController.shared.close()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 440)
    }
    
    // MARK: - General Tab
    @ViewBuilder
    private func generalSection(settingsBindable: Bindable<SettingsModel>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hover & Expansion")
                .font(.system(size: 14, weight: .bold))
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Hover to Expand", isOn: settingsBindable.configuration.hoverEnabled)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Hover Activation Delay")
                        Spacer()
                        Text(String(format: "%.2f s", settingsBindable.configuration.hoverDelay.wrappedValue))
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    Slider(value: settingsBindable.configuration.hoverDelay, in: 0.05...1.0, step: 0.05)
                }
                .disabled(!settingsBindable.configuration.hoverEnabled.wrappedValue)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Collapse Delay")
                        Spacer()
                        Text(String(format: "%.2f s", settingsBindable.configuration.collapseDelay.wrappedValue))
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    Slider(value: settingsBindable.configuration.collapseDelay, in: 0.1...2.0, step: 0.1)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                Toggle("Pin Notch by Default", isOn: settingsBindable.configuration.pinnedByDefault)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    
    // MARK: - Notch Tab
    @ViewBuilder
    private func notchSection(settingsBindable: Bindable<SettingsModel>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notch Dimensions")
                .font(.system(size: 14, weight: .bold))
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Expanded Width")
                        Spacer()
                        Text("\(Int(settingsBindable.configuration.expandedWidth.wrappedValue)) pt")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    Slider(value: settingsBindable.configuration.expandedWidth, in: 480...800, step: 10)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Expanded Height")
                        Spacer()
                        Text("\(Int(settingsBindable.configuration.expandedHeight.wrappedValue)) pt")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    Slider(value: settingsBindable.configuration.expandedHeight, in: 140...300, step: 10)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Corner Radius")
                        Spacer()
                        Text("\(Int(settingsBindable.configuration.cornerRadius.wrappedValue)) pt")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    Slider(value: settingsBindable.configuration.cornerRadius, in: 8...30, step: 1)
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    
    // MARK: - Appearance Tab
    @ViewBuilder
    private func appearanceSection(settingsBindable: Bindable<SettingsModel>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Theme Selection")
                .font(.system(size: 14, weight: .bold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(NotchTheme.allCases) { theme in
                    let isSelected = settingsBindable.configuration.theme.wrappedValue == theme
                    Button {
                        settingsBindable.configuration.theme.wrappedValue = theme
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(theme.gradient(dynamicArtworkColor: nil))
                                .frame(width: 20, height: 20)
                            
                            Text(theme.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 14))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Text("Lighting & Visual Effects")
                .font(.system(size: 14, weight: .bold))
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Ambient Album Art Lighting", isOn: settingsBindable.configuration.lightingEffectEnabled)
                Text("Casts a blurred dynamic glow matching the active track artwork behind the notch.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Toggle("Reduce Effects (Save Energy)", isOn: settingsBindable.configuration.reducedEffects)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
