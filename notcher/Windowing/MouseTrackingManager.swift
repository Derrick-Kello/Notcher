//
//  MouseTrackingManager.swift
//  notcher
//

import AppKit

@MainActor
final class MouseTrackingManager: NSResponder {
    private weak var panel: NotchPanel?
    private weak var stateMachine: NotchStateMachine?
    private var trackingArea: NSTrackingArea?
    private var eventMonitor: Any?
    
    func setupTracking(on panel: NotchPanel, stateMachine: NotchStateMachine) {
        self.panel = panel
        self.stateMachine = stateMachine
        
        // Setup local event monitor for clicks and escape key
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self = self, let stateMachine = self.stateMachine, let panel = self.panel else { return event }
            
            if event.type == .keyDown {
                if event.keyCode == 53 { // Escape key
                    stateMachine.send(.escapePressed)
                    return nil // Consume event
                }
            } else if event.type == .leftMouseDown || event.type == .rightMouseDown {
                // Check if click is inside our panel
                if event.window == panel {
                    stateMachine.send(.clicked)
                }
            }
            
            return event
        }
        
        // Install initial tracking area
        updateTrackingAreas(for: panel.frame)
    }
    
    func updateTrackingAreas(for frame: CGRect) {
        guard let panel = panel, let contentView = panel.contentView else { return }
        
        if let existing = trackingArea {
            contentView.removeTrackingArea(existing)
        }
        
        // The tracking area should be relative to the view's bounds
        let localRect = contentView.bounds
        
        let newArea = NSTrackingArea(
            rect: localRect,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        
        contentView.addTrackingArea(newArea)
        self.trackingArea = newArea
    }
    
    override func mouseEntered(with event: NSEvent) {
        stateMachine?.send(.mouseEntered)
    }
    
    override func mouseExited(with event: NSEvent) {
        stateMachine?.send(.mouseExited)
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
