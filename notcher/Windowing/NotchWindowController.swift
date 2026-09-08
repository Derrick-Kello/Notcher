//
//  NotchWindowController.swift
//  notcher
//

import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {
    
    private let environment: AppEnvironment
    private var windows: [String: NotchPanel] = [:]
    private var observers: [NSObjectProtocol] = []
    
    init(environment: AppEnvironment) {
        self.environment = environment
        setupScreenNotifications()
        adjustWindows()
    }
    
    private func setupScreenNotifications() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.adjustWindows()
        })
        
        let wsCenter = NSWorkspace.shared.notificationCenter
        observers.append(wsCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.adjustWindows()
        })
    }
    
    func show() {
        for window in windows.values {
            window.orderFrontRegardless()
            NotchSpaceManager.shared.notchSpace.windows.insert(window)
        }
    }
    
    func hide() {
        for window in windows.values {
            window.orderOut(nil)
            NotchSpaceManager.shared.notchSpace.windows.remove(window)
        }
    }
    
    func adjustWindows() {
        let currentScreens = NSScreen.screens
        let currentUUIDs = Set(currentScreens.compactMap { screenUUID($0) })
        
        // Remove windows for disconnected screens
        for (uuid, window) in windows where !currentUUIDs.contains(uuid) {
            window.close()
            NotchSpaceManager.shared.notchSpace.windows.remove(window)
            windows.removeValue(forKey: uuid)
        }
        
        // Create or update window for each connected screen
        for screen in currentScreens {
            let uuid = screenUUID(screen)
            let display = DisplayDescriptor.from(screen: screen)
            
            let window: NotchPanel
            if let existing = windows[uuid] {
                window = existing
            } else {
                let rect = NSRect(origin: .zero, size: DisplayGeometry.windowSize)
                window = NotchPanel(contentRect: rect, screenUUID: uuid)
                
                let rootView = NotchRootView(
                    stateMachine: environment.stateMachine,
                    display: display,
                    widgetRegistry: environment.widgetRegistry,
                    configuration: environment.settings.configuration
                )
                window.contentView = NSHostingView(rootView: rootView)
                windows[uuid] = window
            }
            
            // Position at top center of this screen
            let screenFrame = screen.frame
            let originX = screenFrame.origin.x + (screenFrame.width - DisplayGeometry.windowSize.width) / 2.0
            let originY = screenFrame.origin.y + screenFrame.height - DisplayGeometry.windowSize.height
            window.setFrame(NSRect(x: originX, y: originY, width: DisplayGeometry.windowSize.width, height: DisplayGeometry.windowSize.height), display: true)
            
            window.orderFrontRegardless()
            NotchSpaceManager.shared.notchSpace.windows.insert(window)
        }
    }
    
    private func screenUUID(_ screen: NSScreen) -> String {
        if let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            return String(id)
        }
        return "\(screen.frame.origin.x)_\(screen.frame.origin.y)"
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        for window in windows.values {
            window.close()
            NotchSpaceManager.shared.notchSpace.windows.remove(window)
        }
    }
}
