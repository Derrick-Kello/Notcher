//
//  NotchTheme.swift
//  notcher
//

import SwiftUI
import AppKit

public enum NotchTheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case dynamicAlbum = "dynamicAlbum"
    case neon = "neon"
    case sunset = "sunset"
    case emerald = "emerald"
    case appleMusic = "appleMusic"
    case monochrome = "monochrome"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .dynamicAlbum: return "Dynamic Album Art"
        case .neon: return "Neon Cyberpunk"
        case .sunset: return "Sunset Glow"
        case .emerald: return "Emerald Forest"
        case .appleMusic: return "Apple Red"
        case .monochrome: return "Monochrome Minimal"
        }
    }
    
    public var icon: String {
        switch self {
        case .dynamicAlbum: return "sparkles"
        case .neon: return "bolt.fill"
        case .sunset: return "sunset.fill"
        case .emerald: return "leaf.fill"
        case .appleMusic: return "music.note"
        case .monochrome: return "circle.fill"
        }
    }
    
    public func primaryColor(dynamicArtworkColor: Color?) -> Color {
        switch self {
        case .dynamicAlbum:
            return dynamicArtworkColor ?? Color(red: 0.98, green: 0.35, blue: 0.55)
        case .neon:
            return Color(red: 0.0, green: 0.95, blue: 0.95)
        case .sunset:
            return Color(red: 1.0, green: 0.45, blue: 0.2)
        case .emerald:
            return Color(red: 0.2, green: 0.85, blue: 0.45)
        case .appleMusic:
            return Color(red: 0.98, green: 0.2, blue: 0.45)
        case .monochrome:
            return Color.white
        }
    }
    
    public func secondaryColor(dynamicArtworkColor: Color?) -> Color {
        switch self {
        case .dynamicAlbum:
            return (dynamicArtworkColor ?? Color.pink).opacity(0.8)
        case .neon:
            return Color(red: 1.0, green: 0.2, blue: 0.8)
        case .sunset:
            return Color(red: 0.98, green: 0.25, blue: 0.5)
        case .emerald:
            return Color(red: 0.1, green: 0.6, blue: 0.9)
        case .appleMusic:
            return Color(red: 0.85, green: 0.1, blue: 0.35)
        case .monochrome:
            return Color(white: 0.7)
        }
    }
    
    public func gradient(dynamicArtworkColor: Color?) -> LinearGradient {
        LinearGradient(
            colors: [primaryColor(dynamicArtworkColor: dynamicArtworkColor), secondaryColor(dynamicArtworkColor: dynamicArtworkColor)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
