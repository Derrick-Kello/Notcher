//
//  DisplayDescriptor.swift
//  notcher
//
//  Created on 2026-09-08.
//

import AppKit

/// Describes a display's geometry and capabilities for notch positioning.
struct DisplayDescriptor: @unchecked Sendable {
    let screen: NSScreen
    let frame: CGRect
    let visibleFrame: CGRect
    let backingScaleFactor: CGFloat
    let safeAreaInsets: NSEdgeInsets
    let hasNotch: Bool
    let physicalNotchWidth: CGFloat
    let physicalNotchHeight: CGFloat
    
    /// The display's unique identifier
    var displayID: CGDirectDisplayID? {
        screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
    
    /// Whether this is the built-in MacBook display
    var isBuiltIn: Bool {
        guard let displayID = displayID else { return false }
        return CGDisplayIsBuiltin(displayID) != 0
    }
    
    /// Create a DisplayDescriptor from an NSScreen
    static func from(screen: NSScreen) -> DisplayDescriptor {
        let safeArea: NSEdgeInsets
        if #available(macOS 12.0, *) {
            safeArea = screen.safeAreaInsets
        } else {
            safeArea = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        // A screen has a notch if the top safe area inset is significantly larger than zero
        let hasNotch = safeArea.top > 0
        
        var notchWidth: CGFloat = 185
        if #available(macOS 12.0, *) {
            if let leftPad = screen.auxiliaryTopLeftArea?.width,
               let rightPad = screen.auxiliaryTopRightArea?.width,
               leftPad > 0, rightPad > 0 {
                notchWidth = screen.frame.width - leftPad - rightPad + 4
            }
        }
        
        let notchHeight: CGFloat
        if hasNotch {
            notchHeight = safeArea.top
        } else {
            let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
            notchHeight = menuBarHeight > 0 ? menuBarHeight : 32
        }
        
        return DisplayDescriptor(
            screen: screen,
            frame: screen.frame,
            visibleFrame: screen.visibleFrame,
            backingScaleFactor: screen.backingScaleFactor,
            safeAreaInsets: safeArea,
            hasNotch: hasNotch,
            physicalNotchWidth: notchWidth,
            physicalNotchHeight: notchHeight
        )
    }
}
