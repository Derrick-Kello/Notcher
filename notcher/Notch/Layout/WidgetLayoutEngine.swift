import SwiftUI

struct WidgetLayoutEngine {
    enum LayoutMode {
        case collapsed
        case expanded
    }
    
    @ViewBuilder
    static func layout(widgets: [any NotchWidget], mode: LayoutMode) -> some View {
        HStack(spacing: 16) {
            ForEach(widgets, id: \.id) { widget in
                WidgetHost(widget: widget, mode: mode)
            }
        }
        .padding(.horizontal)
    }
}
