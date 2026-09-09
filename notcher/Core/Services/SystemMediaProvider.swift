//
//  SystemMediaProvider.swift
//  notcher
//

import Foundation
import AppKit
import SwiftUI
import Observation

public struct SyncedLyric: Sendable, Equatable {
    public let time: Double
    public let text: String
    
    public init(time: Double, text: String) {
        self.time = time
        self.text = text
    }
}

public enum MediaSource: Sendable, Equatable {
    case none
    case music
    case spotify
}

@MainActor
@Observable
final class SystemMediaProvider: NowPlayingProvider {
    static let shared = SystemMediaProvider()
    
    private(set) var currentItem: NowPlayingItem?
    private(set) var isPlaying: Bool = false
    private(set) var artworkImage: NSImage? = nil
    private(set) var dynamicColor: Color? = nil
    private(set) var currentLyrics: String = ""
    private(set) var syncedLyrics: [SyncedLyric] = []
    private(set) var isFetchingLyrics: Bool = false
    var isAvailable: Bool { currentItem != nil }
    
    private var activeSource: MediaSource = .none
    private var tickerTimer: Timer?
    private var artworkTask: Task<Void, Never>?
    private var lyricsTask: Task<Void, Never>?
    private var lastTrackKey: String = ""
    
    init() {
        setupObservers()
        initialStateCheck()
    }
    
    private func setupObservers() {
        let center = DistributedNotificationCenter.default()
        
        // Apple Music notification (instant, zero permissions required)
        center.addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.handleAppleMusicNotification(notification.userInfo)
        }
        
        // Spotify notification (instant, zero permissions required)
        center.addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.handleSpotifyNotification(notification.userInfo)
        }
        
        // App lifecycle
        let wsCenter = NSWorkspace.shared.notificationCenter
        wsCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if app.bundleIdentifier == "com.apple.Music" && self.activeSource == .music {
                    self.clearMedia()
                } else if app.bundleIdentifier == "com.spotify.client" && self.activeSource == .spotify {
                    self.clearMedia()
                }
            }
        }
        
        wsCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.initialStateCheck()
        }
    }
    
    private func clearMedia() {
        currentItem = nil
        isPlaying = false
        artworkImage = nil
        dynamicColor = nil
        currentLyrics = ""
        syncedLyrics = []
        lastTrackKey = ""
        tickerTimer?.invalidate()
        tickerTimer = nil
    }
    
    // MARK: - Notification Handlers
    private func handleAppleMusicNotification(_ userInfo: [AnyHashable: Any]?) {
        guard let info = userInfo else { return }
        
        let stateString = (info["Player State"] as? String) ?? ""
        let isNowPlaying = stateString.caseInsensitiveCompare("Playing") == .orderedSame
        let title = (info["Name"] as? String) ?? ""
        let artist = (info["Artist"] as? String) ?? ""
        let album = (info["Album"] as? String) ?? ""
        let totalTimeMs = (info["Total Time"] as? Double) ?? 0
        let duration = totalTimeMs > 0 ? (totalTimeMs / 1000.0) : 0
        
        if title.isEmpty && !isNowPlaying {
            if activeSource == .music {
                clearMedia()
            }
            return
        }
        
        activeSource = .music
        isPlaying = isNowPlaying
        
        let prevElapsed = (currentItem?.title == title) ? (currentItem?.elapsedTime ?? 0) : 0
        
        self.currentItem = NowPlayingItem(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: prevElapsed,
            isPlaying: isNowPlaying,
            artworkData: self.currentItem?.artworkData
        )
        
        updatePlaybackTicker()
        
        let trackKey = "Music_\(title)_\(artist)"
        if trackKey != lastTrackKey {
            lastTrackKey = trackKey
            fetchOnlineArtwork(title: title, artist: artist)
            fetchLyrics(title: title, artist: artist, source: .music)
        }
    }
    
    private func handleSpotifyNotification(_ userInfo: [AnyHashable: Any]?) {
        guard let info = userInfo else { return }
        
        let stateString = (info["Player State"] as? String) ?? ""
        let isNowPlaying = stateString.caseInsensitiveCompare("Playing") == .orderedSame
        let title = (info["Name"] as? String) ?? ""
        let artist = (info["Artist"] as? String) ?? ""
        let album = (info["Album"] as? String) ?? ""
        let durationSec = (info["Duration"] as? Double) ?? 0
        let position = (info["Position"] as? Double) ?? 0
        
        if title.isEmpty && !isNowPlaying {
            if activeSource == .spotify {
                clearMedia()
            }
            return
        }
        
        activeSource = .spotify
        isPlaying = isNowPlaying
        
        self.currentItem = NowPlayingItem(
            title: title,
            artist: artist,
            album: album,
            duration: durationSec,
            elapsedTime: position,
            isPlaying: isNowPlaying,
            artworkData: self.currentItem?.artworkData
        )
        
        updatePlaybackTicker()
        
        let trackKey = "Spotify_\(title)_\(artist)"
        if trackKey != lastTrackKey {
            lastTrackKey = trackKey
            fetchOnlineArtwork(title: title, artist: artist)
            fetchLyrics(title: title, artist: artist, source: .spotify)
        }
    }
    
    // MARK: - Initial State Check (Single Query on Launch)
    func initialStateCheck() {
        let runningApps = NSWorkspace.shared.runningApplications
        let isMusicRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        let isSpotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
        
        if !isMusicRunning && !isSpotifyRunning {
            clearMedia()
            return
        }
        
        Task {
            if isMusicRunning {
                let script = """
                tell application "Music"
                    try
                        set pState to (player state is playing)
                        set tName to name of current track
                        set tArtist to artist of current track
                        set tAlbum to album of current track
                        set tPos to player position
                        set tDur to duration of current track
                        return {pState, tName, tArtist, tAlbum, tPos, tDur}
                    on error
                        return {false, "", "", "", 0, 0}
                    end try
                end tell
                """
                if let desc = try? await AppleScriptHelper.execute(script), desc.numberOfItems >= 6 {
                    let playing = desc.atIndex(1)?.booleanValue ?? false
                    let title = desc.atIndex(2)?.stringValue ?? ""
                    let artist = desc.atIndex(3)?.stringValue ?? ""
                    let album = desc.atIndex(4)?.stringValue ?? ""
                    let pos = desc.atIndex(5)?.doubleValue ?? 0
                    let dur = desc.atIndex(6)?.doubleValue ?? 0
                    
                    if !title.isEmpty {
                        self.activeSource = .music
                        self.isPlaying = playing
                        self.currentItem = NowPlayingItem(
                            title: title,
                            artist: artist,
                            album: album,
                            duration: dur,
                            elapsedTime: pos,
                            isPlaying: playing,
                            artworkData: nil
                        )
                        self.updatePlaybackTicker()
                        
                        let trackKey = "Music_\(title)_\(artist)"
                        if trackKey != self.lastTrackKey {
                            self.lastTrackKey = trackKey
                            self.fetchOnlineArtwork(title: title, artist: artist)
                            self.fetchLyrics(title: title, artist: artist, source: .music)
                        }
                        return
                    }
                }
            }
            
            if isSpotifyRunning {
                let script = """
                tell application "Spotify"
                    try
                        set pState to (player state is playing)
                        set tName to name of current track
                        set tArtist to artist of current track
                        set tAlbum to album of current track
                        set tPos to player position
                        set tDur to (duration of current track) / 1000.0
                        return {pState, tName, tArtist, tAlbum, tPos, tDur}
                    on error
                        return {false, "", "", "", 0, 0}
                    end try
                end tell
                """
                if let desc = try? await AppleScriptHelper.execute(script), desc.numberOfItems >= 6 {
                    let playing = desc.atIndex(1)?.booleanValue ?? false
                    let title = desc.atIndex(2)?.stringValue ?? ""
                    let artist = desc.atIndex(3)?.stringValue ?? ""
                    let album = desc.atIndex(4)?.stringValue ?? ""
                    let pos = desc.atIndex(5)?.doubleValue ?? 0
                    let dur = desc.atIndex(6)?.doubleValue ?? 0
                    
                    if !title.isEmpty {
                        self.activeSource = .spotify
                        self.isPlaying = playing
                        self.currentItem = NowPlayingItem(
                            title: title,
                            artist: artist,
                            album: album,
                            duration: dur,
                            elapsedTime: pos,
                            isPlaying: playing,
                            artworkData: nil
                        )
                        self.updatePlaybackTicker()
                        
                        let trackKey = "Spotify_\(title)_\(artist)"
                        if trackKey != self.lastTrackKey {
                            self.lastTrackKey = trackKey
                            self.fetchOnlineArtwork(title: title, artist: artist)
                            self.fetchLyrics(title: title, artist: artist, source: .spotify)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Playback Progress Ticker
    private func updatePlaybackTicker() {
        tickerTimer?.invalidate()
        tickerTimer = nil
        
        guard isPlaying, let item = currentItem, item.duration > 0 else { return }
        
        tickerTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let current = self.currentItem, self.isPlaying else { return }
            let nextElapsed = min(current.duration, current.elapsedTime + 1.0)
            self.currentItem = NowPlayingItem(
                title: current.title,
                artist: current.artist,
                album: current.album,
                duration: current.duration,
                elapsedTime: nextElapsed,
                isPlaying: current.isPlaying,
                artworkData: current.artworkData
            )
        }
    }
    
    // MARK: - Online Artwork Fallback (iTunes Search API)
    private func fetchOnlineArtwork(title: String, artist: String) {
        guard !title.isEmpty else { return }
        
        artworkTask?.cancel()
        artworkTask = Task { [weak self] in
            let cleanTitle = title.replacingOccurrences(of: "\\(.*\\)|\\[.*\\]", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanArtist = artist.replacingOccurrences(of: "\\(.*\\)|\\[.*\\]", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            let query = "\(cleanTitle) \(cleanArtist)".folding(options: .diacriticInsensitive, locale: .current)
            guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=song&limit=1") else { return }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 5.0
            
            guard let (data, _) = try? await URLSession.shared.data(for: request),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first,
                  let artworkUrl100 = first["artworkUrl100"] as? String else { return }
            
            let highResUrlString = artworkUrl100.replacingOccurrences(of: "100x100bb.jpg", with: "600x600bb.jpg")
            guard let highResUrl = URL(string: highResUrlString),
                  let (imageData, _) = try? await URLSession.shared.data(from: highResUrl) else { return }
            
            await MainActor.run {
                guard let self = self, let image = NSImage(data: imageData) else { return }
                self.artworkImage = image
                if let avg = image.extractAverageColor() {
                    self.dynamicColor = Color(avg)
                }
            }
        }
    }
    
    // MARK: - Lyrics Fetching & Parsing
    private func fetchLyrics(title: String, artist: String, source: MediaSource) {
        guard !title.isEmpty else { return }
        
        lyricsTask?.cancel()
        lyricsTask = Task { [weak self] in
            await MainActor.run {
                self?.isFetchingLyrics = true
                self?.currentLyrics = ""
                self?.syncedLyrics = []
            }
            
            // 1. If Apple Music is active, check native Apple Music lyrics
            if source == .music {
                let script = """
                tell application "Music"
                    try
                        if player state is playing or player state is paused then
                            set l to lyrics of current track
                            if l is not missing value and l is not "" then
                                return l
                            end if
                        end if
                    end try
                    return ""
                end tell
                """
                if let desc = try? await AppleScriptHelper.execute(script),
                   let nativeLyrics = desc.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !nativeLyrics.isEmpty {
                    await MainActor.run {
                        self?.currentLyrics = nativeLyrics
                        self?.syncedLyrics = []
                        self?.isFetchingLyrics = false
                    }
                    return
                }
            }
            
            // 2. Query LRCLIB open lyrics database
            let cleanTitle = title.replacingOccurrences(of: "\\(.*\\)|\\[.*\\]", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: .diacriticInsensitive, locale: .current)
            let cleanArtist = artist.replacingOccurrences(of: "\\(.*\\)|\\[.*\\]", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: .diacriticInsensitive, locale: .current)
            
            guard let encTitle = cleanTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encArtist = cleanArtist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://lrclib.net/api/search?track_name=\(encTitle)&artist_name=\(encArtist)") else {
                await MainActor.run { self?.isFetchingLyrics = false }
                return
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 5.0
            
            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let first = jsonArray.first else {
                await MainActor.run { self?.isFetchingLyrics = false }
                return
            }
            
            let plain = (first["plainLyrics"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let synced = (first["syncedLyrics"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let parsedSynced = SystemMediaProvider.parseLRCString(synced)
            
            await MainActor.run {
                self?.currentLyrics = plain.isEmpty ? synced : plain
                self?.syncedLyrics = parsedSynced
                self?.isFetchingLyrics = false
            }
        }
    }
    
    nonisolated static func parseLRCString(_ lrc: String) -> [SyncedLyric] {
        var result: [SyncedLyric] = []
        let lines = lrc.split(separator: "\n")
        let pattern = #"\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        for lineSub in lines {
            let line = String(lineSub)
            let nsString = line as NSString
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))
            guard let match = matches.first, match.numberOfRanges >= 3 else { continue }
            
            let minutesStr = nsString.substring(with: match.range(at: 1))
            let secondsStr = nsString.substring(with: match.range(at: 2))
            let millisStr = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)) : "0"
            
            let minutes = Double(minutesStr) ?? 0
            let seconds = Double(secondsStr) ?? 0
            let millis = (Double(millisStr) ?? 0) / (millisStr.count == 3 ? 1000.0 : (millisStr.count == 2 ? 100.0 : 10.0))
            let time = minutes * 60.0 + seconds + millis
            
            let textStartIndex = match.range.location + match.range.length
            let lyricText = nsString.substring(from: textStartIndex).trimmingCharacters(in: .whitespacesAndNewlines)
            if !lyricText.isEmpty {
                result.append(SyncedLyric(time: time, text: lyricText))
            }
        }
        return result.sorted { $0.time < $1.time }
    }
    
    func lyricLine(at elapsed: Double) -> String {
        if isFetchingLyrics {
            return "Loading lyrics…"
        }
        if !syncedLyrics.isEmpty {
            var low = 0
            var high = syncedLyrics.count - 1
            var candidateIndex = 0
            
            while low <= high {
                let mid = (low + high) / 2
                if syncedLyrics[mid].time <= elapsed {
                    candidateIndex = mid
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
            return syncedLyrics[candidateIndex].text
        }
        
        let trimmed = currentLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let lines = trimmed.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return lines.first ?? trimmed
        }
        return ""
    }
    
    // MARK: - Playback Controls
    func playPause() {
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        isPlaying.toggle()
        updatePlaybackTicker()
        Task {
            await AppleScriptHelper.executeVoid("tell application \"\(appName)\" to playpause")
        }
    }
    
    func next() {
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        Task {
            await AppleScriptHelper.executeVoid("tell application \"\(appName)\" to next track")
        }
    }
    
    func previous() {
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        Task {
            await AppleScriptHelper.executeVoid("tell application \"\(appName)\" to previous track")
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let item = currentItem else { return }
        let clampedTime = max(0, min(time, item.duration))
        self.currentItem = NowPlayingItem(
            title: item.title,
            artist: item.artist,
            album: item.album,
            duration: item.duration,
            elapsedTime: clampedTime,
            isPlaying: item.isPlaying,
            artworkData: item.artworkData
        )
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        Task {
            await AppleScriptHelper.executeVoid("tell application \"\(appName)\" to set player position to \(clampedTime)")
        }
    }
    
    func openMusicApp() {
        let bundleId = activeSource == .spotify ? "com.spotify.client" : "com.apple.Music"
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}
