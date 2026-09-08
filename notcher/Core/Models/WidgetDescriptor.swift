//
//  WidgetDescriptor.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation

/// Metadata describing a widget's identity and configuration.
struct WidgetDescriptor: Codable, Sendable, Identifiable, Equatable {
    let id: String
    var title: String
    var icon: String  // SF Symbol name
    var priority: Int
    var isEnabled: Bool
    
    /// Whether this widget should show content in the collapsed notch
    var showInCollapsed: Bool = false
}
