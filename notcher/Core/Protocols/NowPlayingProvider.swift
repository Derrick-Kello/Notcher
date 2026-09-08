//
//  NowPlayingProvider.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation
import Combine

/// Abstracts media playback state and controls.
/// Implementations can wrap MRMediaRemote, MPNowPlayingInfoCenter, or mock data.
protocol NowPlayingProvider: AnyObject, Observable {
    var currentItem: NowPlayingItem? { get }
    var isPlaying: Bool { get }
    var isAvailable: Bool { get }
    
    func playPause()
    func next()
    func previous()
    func seek(to time: TimeInterval)
}
