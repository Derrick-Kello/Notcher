//
//  NotchWindowController.swift
//  notcher
//

import AppKit
import SwiftUI

@MainActor
final class NotchHostingView<Content: View>: NSHostingView<Content> {
    private let stateMachine: NotchStateMachine
    private let display: DisplayDescriptor
    
    init(rootView: Content, stateMachine: NotchStateMachine, display: DisplayDescriptor) {
        self.stateMachine = stateMachine
        self.display = display
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required dynamic init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }
    
    private func currentNotchRect() -> NSRect {
        let isExpanded: Bool
        switch stateMachine.state {
        case .expanded, .pinned, .expanding, .temporarilyExpanded:
            isExpanded = true
        default:
            isExpanded = false
        }
        
        if isExpanded {
            let width = DisplayGeometry.openNotchSize.width
            let height = DisplayGeometry.openNotchSize.height
            return NSRect(
                x: (bounds.width - width) / 2.0,
                y: bounds.height - height,
                width: width,
                height: height
            )
        } else {
            let mediaProvider = SystemMediaProvider.shared
            let hasActiveMedia = mediaProvider.isAvailable && mediaProvider.currentItem != nil
            let width: CGFloat
            if display.hasNotch {
                width = hasActiveMedia ? (display.physicalNotchWidth + 72) : display.physicalNotchWidth
            } else {
                width = hasActiveMedia ? 260 : 160
            }
            let height = display.physicalNotchHeight
            return NSRect(
                x: (bounds.width - width) / 2.0,
                y: bounds.height - height,
                width: width,
                height: height
            )
        }
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        let rect = currentNotchRect()
        if rect.contains(point) {
            return super.hitTest(point)
        }
        // Points outside the visible notch rect pass directly through to menu bar / desktop
        return nil
    }
}

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
                windows[uuid] = window
            }
            
            let rootView = NotchRootView(
                stateMachine: environment.stateMachine,
                display: display,
                widgetRegistry: environment.widgetRegistry
            )
            window.contentView = NotchHostingView(
                rootView: rootView,
                stateMachine: environment.stateMachine,
                display: display
            )
            
            // Stationary frame anchored at the top center of this screen
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
