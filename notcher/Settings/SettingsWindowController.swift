//
//  SettingsWindowController.swift
//  notcher
//

import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    private override init() {
        super.init()
    }
    
    func showWindow() {
        if window == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 420),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            win.title = "Notcher Settings"
            win.titleVisibility = .visible
            win.isMovableByWindowBackground = true
            win.collectionBehavior = [.managed, .participatesInCycle, .fullScreenAuxiliary]
            win.hidesOnDeactivate = false
            win.isRestorable = true
            win.identifier = NSUserInterfaceItemIdentifier("NotcherSettingsWindow")
            win.contentView = NSHostingView(rootView: SettingsView())
            win.delegate = self
            self.window = win
        }
        
        // Ensure app can take focus
        NSApp.setActivationPolicy(.regular)
        
        if let win = window {
            win.center()
            win.orderFrontRegardless()
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            DispatchQueue.main.async {
                win.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    func close() {
        window?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }
    
    // MARK: - NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        true
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}
