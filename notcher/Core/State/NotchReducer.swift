//
//  NotchReducer.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation

enum NotchSideEffect: Sendable, Equatable {
    case startHoverTimer
    case cancelHoverTimer
    case startCollapseTimer
    case cancelCollapseTimer
    case animateExpansion
    case animateCollapse
    case none
}

enum NotchReducer {
    /// Computes the next state and any associated side effects given a current state and event.
    static func reduce(state: NotchState, event: NotchEvent) -> (NotchState, NotchSideEffect) {
        switch (state, event) {
        
        // Direct programmatic commands
        case (_, .expandRequested):
            return (.expanded, .none)
            
        case (.pinned, .collapseRequested):
            return (.pinned, .none) // Pinned prevents collapsing
            
        case (_, .collapseRequested):
            return (.collapsed, .none)
        
        // From collapsed
        case (.collapsed, .mouseEntered):
            return (.hovering, .startHoverTimer)
        case (.collapsed, .toggleRequested):
            return (.expanded, .none)
            
        // From hovering
        case (.hovering, .timeout):
            return (.expanded, .none)
        case (.hovering, .mouseExited):
            return (.collapsed, .cancelHoverTimer)
            
        // From expanding
        case (.expanding, .expansionCompleted):
            return (.expanded, .none)
            
        // From expanded
        case (.expanded, .mouseExited):
            return (.collapsed, .none)
        case (.expanded, .clicked):
            return (.pinned, .none)
        case (.expanded, .toggleRequested):
            return (.collapsed, .none)
        case (.expanded, .timeout):
            return (.collapsed, .none)
            
        // From pinned
        case (.pinned, .clicked):
            return (.expanded, .none)
        case (.pinned, .unpinRequested):
            return (.expanded, .none)
        case (.pinned, .escapePressed):
            return (.collapsed, .none)
        case (.pinned, .toggleRequested):
            return (.collapsed, .none)
            
        // Pin requested from any open state
        case (_, .pinRequested):
            return (.pinned, .none)
            
        // From collapsing
        case (.collapsing, .mouseEntered):
            return (.expanded, .none)
        case (.collapsing, .collapseCompleted):
            return (.collapsed, .none)
            
        // Display changes force collapse
        case (_, .displayChanged):
            return (.collapsed, .none)
            
        // Default (unhandled transitions remain in the same state with no effects)
        default:
            return (state, .none)
        }
    }
}
