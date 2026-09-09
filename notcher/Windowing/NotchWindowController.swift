//
//  NotchWindowController.swift
//  notcher
//

import AppKit
import SwiftUI

extension Notification.Name {
    static let notchMouseEntered = Notification.Name("com.smarthivelabs.notcher.mouseEntered")
    static let notchMouseExited = Notification.Name("com.smarthivelabs.notcher.mouseExited")
}

@MainActor
final class NotchHostingView<Content: View>: NSHostingView<Content> {
    private let stateMachine: NotchStateMachine
    private let display: DisplayDescriptor
    private var isHoveredInsideNotch = false
    private var trackingAreaRef: NSTrackingArea?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    init(rootView: Content, stateMachine: NotchStateMachine, display: DisplayDescriptor) {
        self.stateMachine = stateMachine
        self.display = display
        super.init(rootView: rootView)
        setupMouseMonitors()
        
        // Update tracking areas when notch expands or collapses
        NotificationCenter.default.addObserver(
            forName: .notchMouseEntered,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTrackingAreas()
        }
        NotificationCenter.default.addObserver(
            forName: .notchMouseExited,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTrackingAreas()
        }
    }
    
    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required dynamic init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }
    
    private func setupMouseMonitors() {
        // Global monitor catches mouse movement across all applications
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkMousePosition(NSEvent.mouseLocation)
            }
        }
        
        // Local monitor catches mouse movement when this app is active
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkMousePosition(NSEvent.mouseLocation)
            return event
        }
    }
    
    private func checkMousePosition(_ screenPoint: NSPoint) {
        guard let window = self.window,
              let screen = window.screen,
              screen.frame.contains(screenPoint) else {
            if isHoveredInsideNotch {
                isHoveredInsideNotch = false
                NotificationCenter.default.post(name: .notchMouseExited, object: nil)
            }
            window?.ignoresMouseEvents = true
            return
        }
        
        let screenRect = currentNotchScreenRect(for: window)
        let isInside = screenRect.contains(screenPoint)
        
        // Dynamically toggle ignoresMouseEvents:
        // When outside the notch, ignoresMouseEvents is TRUE so all clicks pass straight through to underlying apps.
        // When inside the notch, ignoresMouseEvents is FALSE so notch controls and buttons are 100% clickable.
        window.ignoresMouseEvents = !isInside
        
        if isInside && !isHoveredInsideNotch {
            isHoveredInsideNotch = true
            NotificationCenter.default.post(name: .notchMouseEntered, object: nil)
        } else if !isInside && isHoveredInsideNotch {
            isHoveredInsideNotch = false
            NotificationCenter.default.post(name: .notchMouseExited, object: nil)
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let old = trackingAreaRef {
            removeTrackingArea(old)
        }
        let rect = currentNotchViewRect()
        let area = NSTrackingArea(
            rect: rect,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }
    
    private func currentNotchViewRect() -> NSRect {
        let isExpanded: Bool
        switch stateMachine.state {
        case .expanded, .pinned, .expanding, .temporarilyExpanded:
            isExpanded = true
        default:
            isExpanded = false
        }
        
        let width: CGFloat
        let height: CGFloat
        if isExpanded {
            width = DisplayGeometry.openNotchSize.width
            height = DisplayGeometry.openNotchSize.height
        } else {
            width = display.hasNotch ? max(160, display.physicalNotchWidth - 20) : 140
            height = display.physicalNotchHeight
        }
        
        // In flipped NSHostingView (isFlipped == true), y = 0 is the top of the window
        return NSRect(
            x: (bounds.width - width) / 2.0,
            y: 0,
            width: width,
            height: height
        )
    }
    
    private func currentNotchScreenRect(for window: NSWindow) -> NSRect {
        let isExpanded: Bool
        switch stateMachine.state {
        case .expanded, .pinned, .expanding, .temporarilyExpanded:
            isExpanded = true
        default:
            isExpanded = false
        }
        
        let width: CGFloat
        let height: CGFloat
        if isExpanded {
            width = DisplayGeometry.openNotchSize.width
            height = DisplayGeometry.openNotchSize.height
        } else {
            // Strictly physical hardware notch cutout (with 20pt inner margin)
            width = display.hasNotch ? max(160, display.physicalNotchWidth - 20) : 140
            height = display.physicalNotchHeight
        }
        
        let windowFrame = window.frame
        let screenX = windowFrame.origin.x + (windowFrame.width - width) / 2.0
        let screenY = (windowFrame.origin.y + windowFrame.height) - height
        return NSRect(
            x: screenX,
            y: screenY,
            width: width,
            height: height
        )
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        checkMousePosition(NSEvent.mouseLocation)
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        checkMousePosition(NSEvent.mouseLocation)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        checkMousePosition(NSEvent.mouseLocation)
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = convert(point, from: superview)
        let rect = currentNotchViewRect()
        if rect.contains(localPoint) {
            return super.hitTest(point)
        }
        return nil
    }
    
    deinit {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
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
