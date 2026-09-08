import SwiftUI

@MainActor
@Observable
final class WidgetRegistry {
    private var widgets: [String: any NotchWidget] = [:]
    
    func register(_ widget: any NotchWidget) {
        widgets[widget.id] = widget
    }
    
    func unregister(id: String) {
        widgets.removeValue(forKey: id)
    }
    
    func widget(id: String) -> (any NotchWidget)? {
        return widgets[id]
    }
    
    func enabledWidgets(configuration: NotchConfiguration) -> [any NotchWidget] {
        let allEnabledIds = configuration.enabledWidgets
        var result: [any NotchWidget] = []
        for id in allEnabledIds {
            if let w = widgets[id] {
                result.append(w)
            }
        }
        if result.isEmpty {
            return widgets.values.filter { $0.descriptor.isEnabled }.sorted { $0.descriptor.priority > $1.descriptor.priority }
        }
        return result
    }
    
    func allWidgets() -> [any NotchWidget] {
        Array(widgets.values).sorted { $0.descriptor.priority > $1.descriptor.priority }
    }
}
