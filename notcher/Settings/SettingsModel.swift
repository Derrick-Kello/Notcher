import SwiftUI
import Combine

@MainActor
@Observable
final class SettingsModel: SettingsStore {
    var configuration: NotchConfiguration {
        didSet {
            save()
        }
    }
    
    private let defaults = UserDefaults.standard
    private let key = "com.smarthivelabs.notcher.configuration"
    
    init() {
        self.configuration = NotchConfiguration.default
        load()
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(configuration)
            defaults.set(data, forKey: key)
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }
    
    func load() {
        guard let data = defaults.data(forKey: key) else { return }
        do {
            let config = try JSONDecoder().decode(NotchConfiguration.self, from: data)
            self.configuration = config
        } catch {
            print("Failed to load configuration: \(error)")
        }
    }
    
    func resetToDefaults() {
        configuration = NotchConfiguration.default
    }
}
