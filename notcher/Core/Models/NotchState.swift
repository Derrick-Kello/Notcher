//
//  NotchState.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation

/// Represents the current interaction state of the notch overlay.
enum NotchState: String, CaseIterable, Sendable {
    case collapsed
    case hovering
    case expanding
    case expanded
    case pinned
    case collapsing
    case temporarilyExpanded
    
    var isVisible: Bool {
        switch self {
        case .collapsed: return false
        default: return true
        }
    }
    
    var isInteractive: Bool {
        switch self {
        case .expanded, .pinned, .temporarilyExpanded: return true
        default: return false
        }
    }
}
