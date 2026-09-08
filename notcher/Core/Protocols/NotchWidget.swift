//
//  NotchWidget.swift
//  notcher
//
//  Created on 2026-09-08.
//

import SwiftUI

/// Protocol that all notch widgets must conform to.
/// Provides both collapsed (compact) and expanded views.
protocol NotchWidget: Identifiable where ID == String {
    /// Unique widget identifier
    nonisolated var id: String { get }
    
    /// Widget metadata
    var descriptor: WidgetDescriptor { get }
    
    /// Compact view shown in the collapsed notch (optional)
    @ViewBuilder
    func collapsedView() -> AnyView
    
    /// Full view shown in the expanded notch
    @ViewBuilder
    func expandedView() -> AnyView
}

extension NotchWidget {
    /// Default collapsed view returns an empty view
    func collapsedView() -> AnyView {
        AnyView(EmptyView())
    }
}
