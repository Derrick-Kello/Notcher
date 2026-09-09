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
        setupStateObservation()
        adjustWindows()
    }
    
    private func setupStateObservation() {
        // Observe state changes to dynamically resize window bounds
        _ = withObservationTracking {
            _ = environment.stateMachine.state
            _ = SystemMediaProvider.shared.currentItem
            _ = SystemMediaProvider.shared.isPlaying
        } onChange: {
            Task { @MainActor [weak self] in
                self?.updateWindowFrames()
                self?.setupStateObservation()
            }
        }
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
                let rect = frameForDisplay(display, on: screen)
                window = NotchPanel(contentRect: rect, screenUUID: uuid)
                windows[uuid] = window
            }
            
            let rootView = NotchRootView(
                stateMachine: environment.stateMachine,
                display: display,
                widgetRegistry: environment.widgetRegistry
            )
            window.contentView = NSHostingView(rootView: rootView)
            
            updateWindowFrame(window, for: display, on: screen)
            window.orderFrontRegardless()
            NotchSpaceManager.shared.notchSpace.windows.insert(window)
        }
    }
    
    private func updateWindowFrames() {
        for screen in NSScreen.screens {
            let uuid = screenUUID(screen)
            guard let window = windows[uuid] else { continue }
            let display = DisplayDescriptor.from(screen: screen)
            updateWindowFrame(window, for: display, on: screen)
        }
    }
    
    private func isExpanded() -> Bool {
        switch environment.stateMachine.state {
        case .expanded, .pinned, .expanding, .temporarilyExpanded:
            return true
        default:
            return false
        }
    }
    
    private func frameForDisplay(_ display: DisplayDescriptor, on screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let mediaProvider = SystemMediaProvider.shared
        let hasActiveMedia = mediaProvider.isAvailable && mediaProvider.currentItem != nil
        
        if isExpanded() {
            let width = DisplayGeometry.openNotchSize.width
            let height = DisplayGeometry.openNotchSize.height + DisplayGeometry.shadowPadding
            let originX = screenFrame.origin.x + (screenFrame.width - width) / 2.0
            let originY = screenFrame.origin.y + screenFrame.height - height
            return NSRect(x: originX, y: originY, width: width, height: height)
        } else {
            let width: CGFloat
            if display.hasNotch {
                width = hasActiveMedia ? (display.physicalNotchWidth + 72) : display.physicalNotchWidth
            } else {
                width = hasActiveMedia ? 260 : 160
            }
            let height = display.physicalNotchHeight
            let originX = screenFrame.origin.x + (screenFrame.width - width) / 2.0
            let originY = screenFrame.origin.y + screenFrame.height - height
            return NSRect(x: originX, y: originY, width: width, height: height)
        }
    }
    
    private func updateWindowFrame(_ window: NotchPanel, for display: DisplayDescriptor, on screen: NSScreen) {
        let targetFrame = frameForDisplay(display, on: screen)
        if window.frame != targetFrame {
            window.setFrame(targetFrame, display: true)
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
