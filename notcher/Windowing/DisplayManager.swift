//
//  DisplayManager.swift
//  notcher
//

import AppKit
import Observation

@MainActor
@Observable
final class DisplayManager {
    private(set) var activeDisplay: DisplayDescriptor?
    
    init() {
        activeDisplay = resolveActiveDisplay()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(displayConfigurationChanged),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(displayConfigurationChanged),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }
    
    @objc private func displayConfigurationChanged() {
        activeDisplay = resolveActiveDisplay()
    }
    
    func resolveActiveDisplay() -> DisplayDescriptor? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }
        
        // 1. Prefer display with a physical notch
        if let notchScreen = screens.first(where: {
            if #available(macOS 12.0, *) {
                return $0.safeAreaInsets.top > 0
            }
            return false
        }) {
            return DisplayDescriptor.from(screen: notchScreen)
        }
        
        // 2. Prefer built-in display
        if let builtIn = screens.first(where: { DisplayDescriptor.from(screen: $0).isBuiltIn }) {
            return DisplayDescriptor.from(screen: builtIn)
        }
        
        // 3. Fallback to main or first screen
        return DisplayDescriptor.from(screen: NSScreen.main ?? screens[0])
    }
    
    func displayWithMouse() -> DisplayDescriptor? {
        let mouseLocation = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
            return DisplayDescriptor.from(screen: screen)
        }
        return resolveActiveDisplay()
    }
}
