//
//  ExpandedNotchView.swift
//  notcher
//

import SwiftUI
import AppKit

struct ExpandedNotchView: View {
    var stateMachine: NotchStateMachine
    var widgetRegistry: WidgetRegistry
    var configuration: NotchConfiguration
    
    @State private var mediaProvider = SystemMediaProvider.shared
    @State private var batteryProvider = SystemBatteryProvider.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Header Bar
            HStack(alignment: .center, spacing: 12) {
                // Current Date
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    Text(formattedDate())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.leading, 24)
                
                Spacer()
                
                // Battery status
                if batteryProvider.isAvailable {
                    HStack(spacing: 4) {
                        Image(systemName: batteryIconName())
                            .font(.system(size: 12))
                            .foregroundColor(batteryProvider.state.isCharging ? .green : .white.opacity(0.8))
                        Text("\(Int(batteryProvider.state.level * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Pin button
                Button(action: {
                    if stateMachine.state == .pinned {
                        stateMachine.send(.unpinRequested)
                    } else {
                        stateMachine.send(.pinRequested)
                    }
                }) {
                    Image(systemName: stateMachine.state == .pinned ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundColor(stateMachine.state == .pinned ? .yellow : .white.opacity(0.6))
                }
                .buttonStyle(.plain)
                
                // Settings button
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                
                // Close button
                Button(action: {
                    stateMachine.send(.toggleRequested)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 24)
            }
            .padding(.top, 14)
            
            // Main Dashboard Cards
            HStack(spacing: 16) {
                // Media Player Card
                mediaPlayerCard
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Quick Info / Battery / Actions Card
                quickInfoCard
                    .frame(width: 200)
                    .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Media Player Card
    private var mediaPlayerCard: some View {
        HStack(spacing: 14) {
            // Album Art / Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(white: 0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "music.note")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(mediaProvider.currentItem?.title.isEmpty == false ? mediaProvider.currentItem!.title : "No Media Playing")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(mediaProvider.currentItem?.artist.isEmpty == false ? mediaProvider.currentItem!.artist : "Apple Music / Spotify")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                
                // Controls
                HStack(spacing: 16) {
                    Button(action: { mediaProvider.previous() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaProvider.playPause() }) {
                        Image(systemName: mediaProvider.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaProvider.next() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.12).opacity(0.8))
        )
    }
    
    // MARK: - Quick Info Card
    private var quickInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("System")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            
            HStack(spacing: 8) {
                Image(systemName: batteryProvider.state.isCharging ? "bolt.batteryblock.fill" : "battery.100percent")
                    .font(.system(size: 18))
                    .foregroundColor(batteryProvider.state.isCharging ? .green : .blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(batteryProvider.state.level * 100))% Battery")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    Text(batteryProvider.state.isCharging ? "Charging" : (batteryProvider.state.isPluggedIn ? "Power Connected" : "On Battery"))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            HStack {
                Button("Open Music") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Music.app"))
                }
                .font(.system(size: 11))
                .buttonStyle(.borderedProminent)
                .tint(Color(white: 0.2))
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.12).opacity(0.8))
        )
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    private func batteryIconName() -> String {
        let level = batteryProvider.state.level
        if batteryProvider.state.isCharging {
            return "battery.100percent.bolt"
        }
        if level > 0.75 { return "battery.100" }
        if level > 0.50 { return "battery.75" }
        if level > 0.25 { return "battery.50" }
        return "battery.25"
    }
}
