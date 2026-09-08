import SwiftUI

struct WidgetHost: View {
    var widget: any NotchWidget
    var mode: WidgetLayoutEngine.LayoutMode
    
    var body: some View {
        Group {
            if mode == .expanded {
                widget.expandedView()
            } else {
                widget.collapsedView()
            }
        }
    }
}
