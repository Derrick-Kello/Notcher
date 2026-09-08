//
//  NotchEvent.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation

/// Events that can trigger notch state transitions.
enum NotchEvent: Sendable, Equatable {
    // Mouse interaction
    case mouseEntered
    case mouseExited
    case clicked
    
    // Keyboard
    case escapePressed
    
    // Programmatic
    case toggleRequested
    case pinRequested
    case unpinRequested
    
    // Animation lifecycle
    case expansionCompleted
    case collapseCompleted
    
    // Timer
    case timeout
    
    // System
    case displayChanged
    case appActivationChanged(isActive: Bool)
}
