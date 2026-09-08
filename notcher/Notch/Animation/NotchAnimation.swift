import SwiftUI
import AppKit

struct NotchAnimation {
    static func expansion(reducedMotion: Bool) -> Animation {
        if reducedMotion {
            return .easeInOut(duration: 0.15)
        }
        return .spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)
    }
    
    static func collapse(reducedMotion: Bool) -> Animation {
        if reducedMotion {
            return .easeIn(duration: 0.1)
        }
        return .spring(response: 0.25, dampingFraction: 0.85, blendDuration: 0)
    }
    
    static func contentTransition(reducedMotion: Bool) -> AnyTransition {
        if reducedMotion {
            return .opacity.animation(.easeInOut(duration: 0.15))
        }
        return .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
            .animation(.spring(response: 0.3, dampingFraction: 0.8))
    }
    
    @MainActor
    static var prefersReducedMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
}
