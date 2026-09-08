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
    var isAvailable: Bool { currentItem != nil }
    
    private var activeSource: MediaSource = .none
    
    enum MediaSource {
        case none
        case music
        case spotify
    }
    
    init() {
        setupObservers()
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
                elapsedTime: 0,
                isPlaying: isNowPlaying,
                artworkData: nil
            )
        } else if !isNowPlaying && activeSource == .music {
            self.isPlaying = false
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
                elapsedTime: 0,
                isPlaying: isNowPlaying,
                artworkData: nil
            )
        } else if !isNowPlaying && activeSource == .spotify {
            self.isPlaying = false
        }
    }
    
    func playPause() {
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        runAppleScript("tell application \"\(appName)\" to playpause")
        isPlaying.toggle()
    }
    
    func next() {
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        runAppleScript("tell application \"\(appName)\" to next track")
    }
    
    func previous() {
        let appName = activeSource == .spotify ? "Spotify" : "Music"
        runAppleScript("tell application \"\(appName)\" to previous track")
    }
    
    func seek(to time: TimeInterval) {}
    
    private func runAppleScript(_ script: String) {
        Task.detached {
            let appleScript = NSAppleScript(source: script)
            var error: NSDictionary?
            appleScript?.executeAndReturnError(&error)
        }
    }
}

