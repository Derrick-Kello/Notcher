//
//  NotchConfiguration.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation

/// User-configurable notch behavior and appearance.
struct NotchConfiguration: Codable, Sendable, Equatable {
    var hoverEnabled: Bool = true
    var hoverDelay: TimeInterval = 0.15
    var collapseDelay: TimeInterval = 0.3
    var pinnedByDefault: Bool = false
    var enabledWidgets: [String] = []
    var widgetOrder: [String] = []
    var reducedEffects: Bool = false
    var theme: NotchTheme = .dynamicAlbum
    var lightingEffectEnabled: Bool = true
    
    /// Collapsed notch dimensions (logical points)
    var collapsedWidth: CGFloat = 185
    var collapsedHeight: CGFloat = 32
    
    /// Expanded notch dimensions (logical points)
    var expandedWidth: CGFloat = 640
    var expandedHeight: CGFloat = 190
    
    /// Corner radius for the notch shape
    var cornerRadius: CGFloat = 20
    
    static let `default` = NotchConfiguration()
}

