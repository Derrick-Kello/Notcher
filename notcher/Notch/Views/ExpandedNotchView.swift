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
    
    @State private var isDraggingSlider: Bool = false
    @State private var dragProgress: Double = 0
    @State private var selectedDate = Date()
    
    private var progressValue: Double {
        if isDraggingSlider {
            return dragProgress
        }
        guard let item = mediaProvider.currentItem, item.duration > 0 else { return 0 }
        return max(0, min(item.elapsedTime / item.duration, 1.0))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header Bar matching BoringHeader
            headerBar
                .frame(height: 28)
                .padding(.bottom, 6)
            
            // MARK: - Main Content: Music Player (Left) + Calendar (Right)
            HStack(alignment: .top, spacing: 14) {
                musicPlayerSection
                    .frame(maxWidth: .infinity)
                
                calendarSection
                    .frame(width: 215)
            }
            .frame(height: 134)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 12)
        .frame(width: DisplayGeometry.openNotchSize.width - 24, height: DisplayGeometry.openNotchSize.height - 10)
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 0) {
            // Left side
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 7, height: 7)
                Text("Notcher")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Center camera cutout clearance
            Rectangle()
                .fill(display.hasNotch ? Color.black : Color.clear)
                .frame(width: max(0, display.physicalNotchWidth - 10))
            
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
    
    private var primaryThemeColor: Color {
        configuration.theme.primaryColor(dynamicArtworkColor: mediaProvider.dynamicColor)
    }
    
    private var themeGradient: LinearGradient {
        configuration.theme.gradient(dynamicArtworkColor: mediaProvider.dynamicColor)
    }
    
    // MARK: - Music Player Section (Matching BoringNotch MusicPlayerView)
    private var musicPlayerSection: some View {
        HStack(alignment: .center, spacing: 14) {
            // Album Artwork (90 x 90) with Ambient Lighting Glow
            ZStack(alignment: .bottomTrailing) {
                // Ambient lighting backdrop
                if configuration.lightingEffectEnabled {
                    if let artwork = mediaProvider.artworkImage {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .scaleEffect(x: 1.35, y: 1.45)
                            .rotationEffect(.degrees(92))
                            .blur(radius: 35)
                            .opacity(mediaProvider.isPlaying ? 0.65 : 0.0)
                            .animation(.easeInOut(duration: 0.4), value: mediaProvider.isPlaying)
                    } else if mediaProvider.isPlaying {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(primaryThemeColor)
                            .frame(width: 90, height: 90)
                            .scaleEffect(1.3)
                            .blur(radius: 35)
                            .opacity(0.35)
                    }
                }
                
                // Main Artwork button
                Button {
                    mediaProvider.openMusicApp()
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        if let artwork = mediaProvider.artworkImage {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                        } else {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color(white: 0.16))
                                .frame(width: 90, height: 90)
                                .overlay {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 34))
                                        .foregroundColor(primaryThemeColor.opacity(0.6))
                                }
                        }
                        
                        // App Badge Icon
                        Circle()
                            .fill(Color.black)
                            .frame(width: 22, height: 22)
                            .overlay {
                                Image(systemName: mediaProvider.isPlaying ? "play.circle.fill" : "music.note.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(primaryThemeColor)
                            }
                            .offset(x: 4, y: 4)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 90, height: 90)
            
            // Track Info, Lyrics & Controls
            VStack(alignment: .leading, spacing: 2) {
                // Title
                Text(mediaProvider.currentItem?.title.isEmpty == false ? mediaProvider.currentItem!.title : "Not Playing")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Artist & Live Synced Lyrics
                let lyricLine = mediaProvider.lyricLine(at: mediaProvider.currentItem?.elapsedTime ?? 0)
                if !lyricLine.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 8))
                            .foregroundColor(primaryThemeColor)
                        Text(lyricLine)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    .frame(height: 14)
                } else {
                    Text(mediaProvider.currentItem?.artist.isEmpty == false ? mediaProvider.currentItem!.artist : "Apple Music / Spotify")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                        .frame(height: 14)
                }
                
                // Progress Scrubber Bar
                VStack(spacing: 2) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(themeGradient)
                                .frame(width: max(0, min(geo.size.width * CGFloat(progressValue), geo.size.width)), height: 4)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDraggingSlider = true
                                    let newProgress = max(0, min(value.location.x / geo.size.width, 1.0))
                                    dragProgress = newProgress
                                }
                                .onEnded { value in
                                    let finalProgress = max(0, min(value.location.x / geo.size.width, 1.0))
                                    if let duration = mediaProvider.currentItem?.duration, duration > 0 {
                                        mediaProvider.seek(to: duration * finalProgress)
                                    }
                                    isDraggingSlider = false
                                }
                        )
                    }
                    .frame(height: 5)
                    .padding(.top, 2)
                    
                    HStack {
                        let duration = mediaProvider.currentItem?.duration ?? 0
                        let currentElapsed = isDraggingSlider ? (duration * dragProgress) : (mediaProvider.currentItem?.elapsedTime ?? 0)
                        Text(timeString(from: currentElapsed))
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))
                        Spacer()
                        Text(timeString(from: duration))
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                .padding(.top, 2)
                
                // Playback Buttons Toolbar
                HStack(spacing: 14) {
                    HoverButton(icon: "backward.fill", iconColor: .white.opacity(0.8), size: 26, iconSize: 12) {
                        mediaProvider.previous()
                    }
                    
                    Button(action: { mediaProvider.playPause() }) {
                        Circle()
                            .fill(primaryThemeColor)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Image(systemName: mediaProvider.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .shadow(color: primaryThemeColor.opacity(0.4), radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    HoverButton(icon: "forward.fill", iconColor: .white.opacity(0.8), size: 26, iconSize: 12) {
                        mediaProvider.next()
                    }
                    
                    Spacer()
                    
                    // Equalizer visualizer next to controls
                    AudioSpectrumView(isPlaying: mediaProvider.isPlaying, color: primaryThemeColor)
                        .frame(width: 20, height: 13)
                        .padding(.trailing, 4)
                }
                .padding(.top, 2)
            }
        }
    }
    
    // MARK: - Calendar Section (Matching BoringNotch CalendarView - 215pt)
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Month & Year
            HStack {
                Text(currentMonthYearString)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    HoverButton(icon: "chevron.left", iconColor: .white.opacity(0.6), size: 18, iconSize: 9) {
                        shiftDay(by: -1)
                    }
                    HoverButton(icon: "chevron.right", iconColor: .white.opacity(0.6), size: 18, iconSize: 9) {
                        shiftDay(by: 1)
                    }
                }
            }
            
            // 5-Day Horizontal Date Wheel
            HStack(spacing: 6) {
                ForEach(surroundingDays, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    VStack(spacing: 2) {
                        Text(weekdayString(from: date))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(isSelected ? .black.opacity(0.8) : .white.opacity(0.45))
                        
                        Text(dayNumberString(from: date))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isSelected ? .black : (isToday ? .green : .white))
                    }
                    .frame(width: 32, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? Color.white : (isToday ? Color.white.opacity(0.12) : Color.white.opacity(0.04)))
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = date
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Upcoming Events List
            VStack(alignment: .leading, spacing: 3) {
                if calendarProvider.upcomingEvents.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No events today")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 4)
                } else {
                    ForEach(calendarProvider.upcomingEvents.prefix(2)) { event in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(eventColor(for: event))
                                .frame(width: 5, height: 5)
                            
                            Text(event.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                            
                            Spacer(minLength: 4)
                            
                            Text(eventTimeString(for: event))
                                .font(.system(size: 9, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
    
    // MARK: - Date Helpers
    private var currentMonthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var surroundingDays: [Date] {
        let cal = Calendar.current
        return (-2...2).compactMap { cal.date(byAdding: .day, value: $0, to: selectedDate) }
    }
    
    private func shiftDay(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = newDate
            }
        }
    }
    
    private func weekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayNumberString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func eventTimeString(for event: CalendarEvent) -> String {
        if event.isAllDay { return "All Day" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }
    
    private func eventColor(for event: CalendarEvent) -> Color {
        if let hex = event.calendarColor, !hex.isEmpty, let c = colorFromHex(hex) {
            return c
        }
        return .green
    }
    
    private func colorFromHex(_ hex: String) -> Color? {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") { cleanHex.removeFirst() }
        guard let hexValue = UInt64(cleanHex, radix: 16) else { return nil }
        
        let r, g, b, a: Double
        if cleanHex.count == 6 {
            r = Double((hexValue & 0xFF0000) >> 16) / 255.0
            g = Double((hexValue & 0x00FF00) >> 8) / 255.0
            b = Double(hexValue & 0x0000FF) / 255.0
            a = 1.0
        } else if cleanHex.count == 8 {
            r = Double((hexValue & 0xFF000000) >> 24) / 255.0
            g = Double((hexValue & 0x00FF0000) >> 16) / 255.0
            b = Double((hexValue & 0x0000FF00) >> 8) / 255.0
            a = Double(hexValue & 0x000000FF) / 255.0
        } else {
            return nil
        }
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let safeInterval = max(0, interval)
        let minutes = Int(safeInterval) / 60
        let seconds = Int(safeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
