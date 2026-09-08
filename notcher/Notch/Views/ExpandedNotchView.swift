//
//  ExpandedNotchView.swift
//  notcher
//

import SwiftUI
import AppKit

struct ExpandedNotchView: View {
    var stateMachine: NotchStateMachine
    var display: DisplayDescriptor
    var widgetRegistry: WidgetRegistry
    var configuration: NotchConfiguration
    
    @State private var mediaProvider = SystemMediaProvider.shared
    @State private var batteryProvider = SystemBatteryProvider.shared
    @State private var calendarProvider = SystemCalendarProvider.shared
    
    @State private var progressValue: Double = 0.35
    @State private var isDraggingSlider: Bool = false
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header Bar matching BoringHeader
            headerBar
                .frame(height: 30)
                .padding(.bottom, 6)
            
            // MARK: - Main Content: Music Player (Left) + Calendar (Right)
            HStack(alignment: .top, spacing: 14) {
                musicPlayerSection
                    .frame(maxWidth: .infinity)
                
                calendarSection
                    .frame(width: 215)
            }
            .frame(height: 130)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .frame(width: DisplayGeometry.openNotchSize.width - 24, height: DisplayGeometry.openNotchSize.height - 12)
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 0) {
            // Left side
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 7, height: 7)
                Text("Notcher")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Center camera cutout clearance
            Rectangle()
                .fill(display.hasNotch ? Color.black : Color.clear)
                .frame(width: display.physicalNotchWidth)
            
            // Right side: Settings & Battery
            HStack(spacing: 8) {
                // Battery Indicator
                if batteryProvider.isAvailable {
                    HStack(spacing: 4) {
                        Image(systemName: batteryProvider.state.isCharging ? "bolt.fill" : "battery.100")
                            .font(.system(size: 11))
                            .foregroundColor(batteryProvider.state.isCharging ? .green : .white.opacity(0.8))
                        Text("\(Int(batteryProvider.state.level * 100))%")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                
                // Pin Button
                HoverButton(
                    icon: stateMachine.state == .pinned ? "pin.fill" : "pin",
                    iconColor: stateMachine.state == .pinned ? .yellow : .white.opacity(0.7),
                    size: 26,
                    iconSize: 11
                ) {
                    if stateMachine.state == .pinned {
                        stateMachine.send(.unpinRequested)
                    } else {
                        stateMachine.send(.pinRequested)
                    }
                }
                
                // Settings Button
                HoverButton(
                    icon: "gearshape",
                    iconColor: .white.opacity(0.7),
                    size: 26,
                    iconSize: 11
                ) {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    // MARK: - Music Player Section (Matching BoringNotch MusicPlayerView)
    private var musicPlayerSection: some View {
        HStack(alignment: .center, spacing: 14) {
            // Album Artwork (90 x 90)
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color(white: 0.16))
                    .frame(width: 90, height: 90)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 34))
                            .foregroundColor(.white.opacity(0.25))
                    }
                
                // App Badge Icon
                Circle()
                    .fill(Color.black)
                    .frame(width: 22, height: 22)
                    .overlay {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: 4)
            }
            .frame(width: 90, height: 90)
            
            // Track Info & Controls
            VStack(alignment: .leading, spacing: 3) {
                // Title
                Text(mediaProvider.currentItem?.title.isEmpty == false ? mediaProvider.currentItem!.title : "Not Playing")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Artist
                Text(mediaProvider.currentItem?.artist.isEmpty == false ? mediaProvider.currentItem!.artist : "Apple Music / Spotify")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                
                // Progress Scrubber Bar
                VStack(spacing: 3) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(Color.white)
                                .frame(width: max(0, min(geo.size.width * CGFloat(progressValue), geo.size.width)), height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 4)
                    
                    HStack {
                        Text(timeString(from: (mediaProvider.currentItem?.duration ?? 0) * progressValue))
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))
                        Spacer()
                        Text(timeString(from: mediaProvider.currentItem?.duration ?? 0))
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                .padding(.top, 2)
                
                // Playback Buttons Toolbar
                HStack(spacing: 16) {
                    HoverButton(icon: "shuffle", iconColor: .white.opacity(0.6), size: 28, iconSize: 12) {}
                    
                    HoverButton(icon: "backward.fill", iconColor: .white.opacity(0.8), size: 28, iconSize: 13) {
                        mediaProvider.previous()
                    }
                    
                    Button(action: { mediaProvider.playPause() }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: mediaProvider.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                            }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    HoverButton(icon: "forward.fill", iconColor: .white.opacity(0.8), size: 28, iconSize: 13) {
                        mediaProvider.next()
                    }
                    
                    HoverButton(icon: "speaker.wave.2.fill", iconColor: .white.opacity(0.6), size: 28, iconSize: 12) {}
                }
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
    
    // MARK: - Calendar Section (Matching BoringNotch CalendarView)
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Month & Year
            HStack {
                Text(Date().formatted(.dateTime.month(.abbreviated).year()))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(Date().formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Mini Day Picker Pill
            HStack(spacing: 6) {
                ForEach(-2...2, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
                    let isToday = dayOffset == 0
                    
                    VStack(spacing: 2) {
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(isToday ? .white : .white.opacity(0.45))
                        
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 11, weight: isToday ? .bold : .medium, design: .rounded))
                            .foregroundColor(isToday ? .white : .white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(isToday ? Color.accentColor : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            // Events List or Empty State
            if calendarProvider.upcomingEvents.isEmpty {
                VStack(spacing: 2) {
                    Spacer(minLength: 0)
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        Text("No upcoming events")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(calendarProvider.upcomingEvents.prefix(2)) { event in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 4, height: 4)
                            Text(event.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer()
                            Text(event.startDate.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
    
    private func timeString(from seconds: Double) -> String {
        let total = max(0, Int(seconds))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
