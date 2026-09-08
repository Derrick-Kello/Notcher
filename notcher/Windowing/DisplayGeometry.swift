//
//  DisplayGeometry.swift
//  notcher
//

import Foundation
import CoreGraphics

struct DisplayGeometry {
    static let openNotchSize = CGSize(width: 640, height: 190)
    static let shadowPadding: CGFloat = 20
    static let windowSize = CGSize(width: openNotchSize.width, height: openNotchSize.height + shadowPadding)
    
    /// Corner radii for the notch shape matching BoringNotch
    static let closedCornerRadii = (top: CGFloat(6), bottom: CGFloat(14))
    static let openCornerRadii = (top: CGFloat(19), bottom: CGFloat(24))

    /// Stationary window frame anchored at the top-center of the display
    static func windowFrame(for display: DisplayDescriptor) -> CGRect {
        let screenFrame = display.frame
        let originX = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2.0
        let originY = screenFrame.origin.y + screenFrame.height - windowSize.height
        return CGRect(origin: CGPoint(x: originX, y: originY), size: windowSize)
    }

    /// Calculate closed notch size (width & height) for the display
    static func closedNotchSize(for display: DisplayDescriptor, config: NotchConfiguration? = nil) -> CGSize {
        let width = display.physicalNotchWidth
        let height = display.physicalNotchHeight
        return CGSize(width: width, height: height)
    }
}
