//
//  SystemCalendarProvider.swift
//  notcher
//

import Foundation
import AppKit
import EventKit
import Observation

@MainActor
@Observable
final class SystemCalendarProvider: CalendarProvider {
    static let shared = SystemCalendarProvider()
    
    private let eventStore = EKEventStore()
    private(set) var upcomingEvents: [CalendarEvent] = []
    private(set) var isAuthorized: Bool = false
    var isAvailable: Bool { true }
    
    init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            isAuthorized = (status == .fullAccess)
        } else {
            isAuthorized = (status == .authorized)
        }
        if isAuthorized {
            refresh()
        }
    }
    
    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            self.isAuthorized = granted
            if granted {
                refresh()
            }
            return granted
        } catch {
            return false
        }
    }
    
    func refresh() {
        guard isAuthorized else { return }
        
        let now = Date()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        let predicate = eventStore.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        self.upcomingEvents = ekEvents.prefix(5).map { event in
            CalendarEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Event",
                startDate: event.startDate ?? now,
                endDate: event.endDate ?? now.addingTimeInterval(3600),
                isAllDay: event.isAllDay,
                calendarColor: event.calendar.color.cgColor.components?.map { String(format: "%02lX", Int($0 * 255)) }.joined()
            )
        }
    }
}
