//
//  SystemMediaProvider.swift
//  notcher
//

import Foundation
import AppKit
import Observation

@MainActor
@Observable
final class SystemMediaProvider: NowPlayingProvider {
    static let shared = SystemMediaProvider()
    
    private(set) var currentItem: NowPlayingItem?
    private(set) var isPlaying: Bool = false
    private(set) var artworkImage: NSImage? = nil
    var isAvailable: Bool { currentItem != nil }
    
    private var activeSource: MediaSource = .none
    private var tickerTimer: Timer?
    private var fetchTask: Task<Void, Never>?
    
    enum MediaSource {
        case none
        case music
        case spotify
    }
    
    init() {
        setupObservers()
        // Initial check for currently running media apps
        refreshActiveMedia()
    }
    
    private func setupObservers() {
        let center = DistributedNotificationCenter.default()
        
        // Apple Music notification
        center.addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleMusicNotification(notification)
            }
        }
        
        // Spotify notification
        center.addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleSpotifyNotification(notification)
            }
        }
    }
    
    func refreshActiveMedia() {
        if NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == "com.apple.Music" }) {
            activeSource = .music
            fetchMusicDetails()
        } else if NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == "com.spotify.client" }) {
            activeSource = .spotify
            fetchSpotifyDetails()
        }
    }
    
    private func handleMusicNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let state = userInfo["Player State"] as? String ?? ""
        let isNowPlaying = (state == "Playing")
        let title = userInfo["Name"] as? String ?? ""
        let artist = userInfo["Artist"] as? String ?? ""
        let album = userInfo["Album"] as? String ?? ""
        let totalTime = (userInfo["Total Time"] as? Double ?? 0) / 1000.0
        
        if !title.isEmpty {
            self.activeSource = .music
            self.isPlaying = isNowPlaying
            self.currentItem = NowPlayingItem(
                title: title,
                artist: artist,
                album: album,
                duration: totalTime,
                elapsedTime: self.currentItem?.elapsedTime ?? 0,
                isPlaying: isNowPlaying,
                artworkData: self.currentItem?.artworkData
            )
            updatePlaybackTicker()
            fetchMusicDetails()
        } else if !isNowPlaying && activeSource == .music {
            self.isPlaying = false
            updatePlaybackTicker()
        }
    }
    
    private func handleSpotifyNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let state = userInfo["Player State"] as? String ?? ""
        let isNowPlaying = (state == "Playing" || state == "kPSP")
        let title = userInfo["Name"] as? String ?? ""
        let artist = userInfo["Artist"] as? String ?? ""
        let album = userInfo["Album"] as? String ?? ""
        let duration = (userInfo["Duration"] as? Double ?? 0) / 1000.0
        
        if !title.isEmpty {
            self.activeSource = .spotify
            self.isPlaying = isNowPlaying
            self.currentItem = NowPlayingItem(
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                elapsedTime: self.currentItem?.elapsedTime ?? 0,
                isPlaying: isNowPlaying,
                artworkData: self.currentItem?.artworkData
            )
            updatePlaybackTicker()
            fetchSpotifyDetails()
        } else if !isNowPlaying && activeSource == .spotify {
            self.isPlaying = false
            updatePlaybackTicker()
        }
    }
    
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
    
    private func fetchMusicDetails() {
        fetchTask?.cancel()
        fetchTask = Task.detached(priority: .userInitiated) { [weak self] in
            let script = """
            tell application "Music"
                try
                    set playerState to (player state is playing)
                    set currentTrackName to name of current track
                    set currentTrackArtist to artist of current track
                    set currentTrackAlbum to album of current track
                    set trackPosition to player position
                    set trackDuration to duration of current track
                    try
                        set artData to data of artwork 1 of current track
                    on error
                        set artData to ""
                    end try
                    return {playerState, currentTrackName, currentTrackArtist, currentTrackAlbum, trackPosition, trackDuration, artData}
                on error
                    return {false, "", "", "", 0, 0, ""}
                end try
            end tell
            """
            
            guard let desc = try? await AppleScriptHelper.execute(script) else { return }
            guard desc.numberOfItems >= 6 else { return }
            
            let isPlaying = desc.atIndex(1)?.booleanValue ?? false
            let title = desc.atIndex(2)?.stringValue ?? ""
            let artist = desc.atIndex(3)?.stringValue ?? ""
            let album = desc.atIndex(4)?.stringValue ?? ""
            let position = desc.atIndex(5)?.doubleValue ?? 0
            let duration = desc.atIndex(6)?.doubleValue ?? 0
            let artRawData = desc.atIndex(7)?.data
            
            guard !title.isEmpty else { return }
            
            var image: NSImage? = nil
            if let data = artRawData, !data.isEmpty {
                image = NSImage(data: data)
            }
            
            await MainActor.run {
                guard let self = self else { return }
                self.activeSource = .music
                self.isPlaying = isPlaying
                self.artworkImage = image
                self.currentItem = NowPlayingItem(
                    title: title,
                    artist: artist,
                    album: album,
                    duration: duration,
                    elapsedTime: position,
                    isPlaying: isPlaying,
                    artworkData: artRawData
                )
                self.updatePlaybackTicker()
            }
        }
    }
    
    private func fetchSpotifyDetails() {
        fetchTask?.cancel()
        fetchTask = Task.detached(priority: .userInitiated) { [weak self] in
            let script = """
            tell application "Spotify"
                try
                    set playerState to (player state is playing)
                    set currentTrackName to name of current track
                    set currentTrackArtist to artist of current track
                    set currentTrackAlbum to album of current track
                    set trackPosition to player position
                    set trackDuration to (duration of current track) / 1000.0
                    set artUrl to artwork url of current track
                    return {playerState, currentTrackName, currentTrackArtist, currentTrackAlbum, trackPosition, trackDuration, artUrl}
                on error
                    return {false, "", "", "", 0, 0, ""}
                end try
            end tell
            """
            
            guard let desc = try? await AppleScriptHelper.execute(script) else { return }
            guard desc.numberOfItems >= 6 else { return }
            
            let isPlaying = desc.atIndex(1)?.booleanValue ?? false
            let title = desc.atIndex(2)?.stringValue ?? ""
            let artist = desc.atIndex(3)?.stringValue ?? ""
            let album = desc.atIndex(4)?.stringValue ?? ""
            let position = desc.atIndex(5)?.doubleValue ?? 0
            let duration = desc.atIndex(6)?.doubleValue ?? 0
            let artUrlString = desc.atIndex(7)?.stringValue ?? ""
            
            guard !title.isEmpty else { return }
            
            var image: NSImage? = nil
            var artData: Data? = nil
            if let url = URL(string: artUrlString), !artUrlString.isEmpty {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    artData = data
                    image = NSImage(data: data)
                }
            }
            
            await MainActor.run {
                guard let self = self else { return }
                self.activeSource = .spotify
                self.isPlaying = isPlaying
                if let image = image {
                    self.artworkImage = image
                }
                self.currentItem = NowPlayingItem(
                    title: title,
                    artist: artist,
                    album: album,
                    duration: duration,
                    elapsedTime: position,
                    isPlaying: isPlaying,
                    artworkData: artData ?? self.currentItem?.artworkData
                )
                self.updatePlaybackTicker()
            }
        }
    }
    
    func playPause() {
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        isPlaying.toggle()
        updatePlaybackTicker()
        Task {
            await AppleScriptHelper.executeVoid("tell application \"\(appName)\" to playpause")
            if self.activeSource == .music {
                self.fetchMusicDetails()
            } else {
                self.fetchSpotifyDetails()
            }
        }
    }
    
    func next() {
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        Task {
            await AppleScriptHelper.executeVoid("tell application \"\(appName)\" to next track")
            try? await Task.sleep(nanoseconds: 200_000_000)
            if self.activeSource == .music {
                self.fetchMusicDetails()
            } else {
                self.fetchSpotifyDetails()
            }
        }
    }
    
    func previous() {
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        Task {
            await AppleScriptHelper.executeVoid("tell application \"\(appName)\" to previous track")
            try? await Task.sleep(nanoseconds: 200_000_000)
            if self.activeSource == .music {
                self.fetchMusicDetails()
            } else {
                self.fetchSpotifyDetails()
            }
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
}
