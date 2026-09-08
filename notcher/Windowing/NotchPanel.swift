//
//  NotchPanel.swift
//  notcher
//

import AppKit
import SwiftUI

@MainActor
final class NotchPanel: NSPanel {
    let screenUUID: String

    init(contentRect: NSRect, screenUUID: String = "") {
        self.screenUUID = screenUUID
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow]
        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
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
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
