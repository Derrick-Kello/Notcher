import Foundation
import CoreGraphics
import AppKit

struct NotchLayoutEngine {
    static func size(for state: NotchState, configuration: NotchConfiguration) -> CGSize {
        switch state {
        case .collapsed, .hovering, .collapsing:
            return CGSize(width: configuration.collapsedWidth, height: configuration.collapsedHeight)
        case .expanding, .expanded, .pinned, .temporarilyExpanded:
            return CGSize(width: configuration.expandedWidth, height: configuration.expandedHeight)
        }
    }
    
    static func targetFrame(for state: NotchState, configuration: NotchConfiguration, display: DisplayDescriptor) -> CGRect {
        let size = self.size(for: state, configuration: configuration)
        let screenFrame = display.visibleFrame
        let x = screenFrame.minX + (screenFrame.width - size.width) / 2.0
        let y = screenFrame.maxY - size.height
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
