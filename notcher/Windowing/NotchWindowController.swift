//
//  NotchWindowController.swift
//  notcher
//

import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {
    
    private let panel: NotchPanel
    private let environment: AppEnvironment
    private var activeDisplay: DisplayDescriptor?
    private var observers: [NSObjectProtocol] = []
    
    init(environment: AppEnvironment) {
        self.environment = environment
        self.panel = NotchPanel()
        self.panel.stateMachine = environment.stateMachine
        
        let rootView = NotchRootView(
            stateMachine: environment.stateMachine,
            displayManager: environment.displayManager,
            widgetRegistry: environment.widgetRegistry,
            configuration: environment.settings.configuration
        )
        
        let hostingView = NSHostingView(rootView: rootView)
        panel.contentView = hostingView
        
        setupScreenNotifications()
        
        if let display = environment.displayManager.resolveActiveDisplay() {
            updateForDisplay(display)
        }
    }
    
    private func setupScreenNotifications() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if let display = self.environment.displayManager.resolveActiveDisplay() {
                self.updateForDisplay(display)
            }
        })
        
        let wsCenter = NSWorkspace.shared.notificationCenter
        observers.append(wsCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if let display = self.environment.displayManager.resolveActiveDisplay() {
                self.updateForDisplay(display)
            }
        })
    }
    
    func show() {
        panel.orderFrontRegardless()
        updatePosition()
    }
    
    func hide() {
        panel.orderOut(nil)
    }
    
    func updatePosition() {
        guard let display = activeDisplay ?? environment.displayManager.resolveActiveDisplay() else { return }
        activeDisplay = display
        
        let frame = DisplayGeometry.windowFrame(for: display)
        panel.setFrame(frame, display: true)
    }
    
    func updateForDisplay(_ display: DisplayDescriptor) {
        self.activeDisplay = display
        updatePosition()
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
