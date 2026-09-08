//
//  NowPlayingItem.swift
//  notcher
//
//  Created on 2026-09-08.
//

import AppKit

/// Represents the currently playing media item.
struct NowPlayingItem: Sendable, Equatable {
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let elapsedTime: TimeInterval
    let isPlaying: Bool
    let artworkData: Data?
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(elapsedTime / duration, 1.0)
    }
    
    var remainingTime: TimeInterval {
        max(duration - elapsedTime, 0)
    }
    
    static let empty = NowPlayingItem(
        title: "", artist: "", album: "",
        duration: 0, elapsedTime: 0,
        isPlaying: false, artworkData: nil
    )
}
