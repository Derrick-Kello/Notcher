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
        
        // From collapsed
        case (.collapsed, .mouseEntered):
            return (.hovering, .startHoverTimer)
        case (.collapsed, .toggleRequested):
            return (.expanding, .animateExpansion)
            
        // From hovering
        case (.hovering, .timeout):
            return (.expanding, .animateExpansion)
        case (.hovering, .mouseExited):
            return (.collapsed, .cancelHoverTimer)
            
        // From expanding
        case (.expanding, .expansionCompleted):
            return (.expanded, .none)
            
        // From expanded
        case (.expanded, .mouseExited):
            return (.collapsing, .animateCollapse)
        case (.expanded, .clicked):
            return (.pinned, .none)
        case (.expanded, .toggleRequested):
            return (.collapsing, .animateCollapse)
        case (.expanded, .timeout):
            return (.collapsing, .animateCollapse)
            
        // From pinned
        case (.pinned, .clicked):
            return (.expanded, .none)
        case (.pinned, .unpinRequested):
            return (.expanded, .none)
        case (.pinned, .escapePressed):
            return (.collapsing, .animateCollapse)
        case (.pinned, .toggleRequested):
            return (.collapsing, .animateCollapse)
            
        // Pin requested from any open state
        case (.expanded, .pinRequested), (.expanding, .pinRequested), (.temporarilyExpanded, .pinRequested):
            return (.pinned, .none)
        case (_, .pinRequested):
            return (.pinned, .none)
            
        // From collapsing
        case (.collapsing, .mouseEntered):
            return (.expanding, .animateExpansion)
        case (.collapsing, .collapseCompleted):
            return (.collapsed, .none)
            
        // Display changes force collapse
        case (_, .displayChanged):
            return (.collapsed, .animateCollapse)
            
        // Default (unhandled transitions remain in the same state with no effects)
        default:
            return (state, .none)
        }
    }
}
