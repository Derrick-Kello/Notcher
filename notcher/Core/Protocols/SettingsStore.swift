//
//  SettingsStore.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation

/// Protocol for persisting and retrieving app settings.
protocol SettingsStore: AnyObject, Observable {
    var configuration: NotchConfiguration { get set }
    
    /// Save current configuration to persistent storage
    func save()
    
    /// Load configuration from persistent storage
    func load()
    
    /// Reset to default configuration
    func resetToDefaults()
}
