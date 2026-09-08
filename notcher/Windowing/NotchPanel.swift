//
//  NotchPanel.swift
//  notcher
//

import AppKit
import SwiftUI

@MainActor
final class NotchPanel: NSPanel {
    weak var stateMachine: NotchStateMachine?

    init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: DisplayGeometry.windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.isOpaque = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.backgroundColor = .clear
        self.isMovable = false
        self.hasShadow = false
        self.isReleasedWhenClosed = false
        self.level = .mainMenu + 3
        
        self.collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle
        ]
        
        self.appearance = NSAppearance(named: .darkAqua)
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
    }
    
    override var canBecomeKey: Bool {
        false
    }
    
    override var canBecomeMain: Bool {
        false
    }
}
