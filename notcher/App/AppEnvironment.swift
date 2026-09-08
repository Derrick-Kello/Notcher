import Foundation
import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    static let shared = AppEnvironment()
    
    let settings: SettingsModel
    let displayManager: DisplayManager
    let widgetRegistry: WidgetRegistry
    let stateMachine: NotchStateMachine
    
    private init() {
        let settings = SettingsModel()
        settings.load()
        
        self.settings = settings
        self.displayManager = DisplayManager()
        self.widgetRegistry = WidgetRegistry()
        self.stateMachine = NotchStateMachine(configuration: settings.configuration)
    }
}
