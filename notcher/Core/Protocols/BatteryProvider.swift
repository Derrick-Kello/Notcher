//
//  BatteryProvider.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation

/// Battery state information.
struct BatteryState: Sendable, Equatable {
    let level: Double  // 0.0 to 1.0
    let isCharging: Bool
    let isPluggedIn: Bool
    let timeRemaining: TimeInterval?  // seconds, nil if unknown
    
    static let unknown = BatteryState(level: 0, isCharging: false, isPluggedIn: false, timeRemaining: nil)
}

/// Abstracts battery status reporting.
protocol BatteryProvider: AnyObject, Observable {
    var state: BatteryState { get }
    var isAvailable: Bool { get }
}
