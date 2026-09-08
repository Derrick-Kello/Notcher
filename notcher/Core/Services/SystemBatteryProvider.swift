//
//  SystemBatteryProvider.swift
//  notcher
//

import Foundation
import IOKit.ps
import Observation

@MainActor
@Observable
final class SystemBatteryProvider: BatteryProvider {
    static let shared = SystemBatteryProvider()
    
    private(set) var state: BatteryState = .unknown
    var isAvailable: Bool {
        state != .unknown
    }
    
    private var timer: Timer?
    
    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
    
    func refresh() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            self.state = .unknown
            return
        }
        
        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            let current = desc[kIOPSCurrentCapacityKey] as? Double ?? 0
            let maxCapacity = desc[kIOPSMaxCapacityKey] as? Double ?? 100
            let isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false
            let isPluggedIn = (desc[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            let rawLevel = maxCapacity > 0 ? (current / maxCapacity) : 0
            let clampedLevel = Swift.min(Swift.max(rawLevel, 0.0), 1.0)
            
            self.state = BatteryState(
                level: clampedLevel,
                isCharging: isCharging,
                isPluggedIn: isPluggedIn,
                timeRemaining: nil
            )
            return
        }
        
        self.state = .unknown
    }
}

