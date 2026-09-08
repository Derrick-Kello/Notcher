//
//  WindowBehavior.swift
//  notcher
//

import AppKit

struct WindowBehavior {
    
    static func configureCollectionBehavior(for panel: NSPanel, state: NotchState) {
        if state.isInteractive {
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        } else {
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        }
    }
    
    static func registerSleepWakeNotifications(observer: Any, sleepSelector: Selector, wakeSelector: Selector) {
        NSWorkspace.shared.notificationCenter.addObserver(
            observer,
            selector: sleepSelector,
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            observer,
            selector: wakeSelector,
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }
    
    static func registerDisplayNotifications(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    static func shouldBeVisible(display: DisplayDescriptor?, isActive: Bool) -> Bool {
        guard display != nil else { return false }
        // Extend with further space/fullscreen checks if necessary
        return true
    }
}
