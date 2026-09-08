//
//  CalendarProvider.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation

/// A simplified calendar event for display.
struct CalendarEvent: Sendable, Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: String?  // hex color
    
    var isOngoing: Bool {
        let now = Date()
        return startDate <= now && now <= endDate
    }
}

/// Abstracts calendar event retrieval.
protocol CalendarProvider: AnyObject, Observable {
    var upcomingEvents: [CalendarEvent] { get }
    var isAvailable: Bool { get }
    var isAuthorized: Bool { get }
    
    func requestAccess() async -> Bool
    func refresh()
}
