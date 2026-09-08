//
//  CollapsedNotchView.swift
//  notcher
//

import SwiftUI
import AppKit

struct CollapsedNotchView: View {
    var stateMachine: NotchStateMachine
    var display: DisplayDescriptor
    var configuration: NotchConfiguration
    
    @State private var mediaProvider = SystemMediaProvider.shared
    
    private var hasActiveMedia: Bool {
        mediaProvider.isAvailable && mediaProvider.currentItem != nil
    }
    
    var body: some View {
        let height = display.physicalNotchHeight
        let artSize: CGFloat = max(16, min(24, height - 14))
        let themeColor = configuration.theme.primaryColor(dynamicArtworkColor: mediaProvider.dynamicColor)
        
        if display.hasNotch {
            if hasActiveMedia {
                HStack(spacing: 0) {
                    // Left Ear: Album Artwork or Music Note Icon
                    HStack {
                        if let artwork = mediaProvider.artworkImage {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: artSize, height: artSize)
                                .clipShape(RoundedRectangle(cornerRadius: 4.5, style: .continuous))
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(themeColor)
                                .frame(width: artSize, height: artSize)
                        }
                    }
                    .frame(width: 36, height: height, alignment: .center)
                    
                    // Center Clearance: Perfectly matches physical MacBook hardware notch
                    Spacer(minLength: 0)
                        .frame(width: display.physicalNotchWidth)
                    
                    // Right Ear: Animated Audio Spectrum Equalizer Bars
                    HStack {
                        AudioSpectrumView(isPlaying: mediaProvider.isPlaying, color: themeColor)
                            .frame(width: 16, height: 11)
                    }
                    .frame(width: 36, height: height, alignment: .center)
                }
                .frame(width: display.physicalNotchWidth + 72, height: height)
            } else {
                Color.clear
                    .frame(width: display.physicalNotchWidth, height: height)
            }
        } else {
            // External monitor without hardware notch
            if hasActiveMedia, let item = mediaProvider.currentItem {
                HStack(spacing: 6) {
                    if let artwork = mediaProvider.artworkImage {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: artSize, height: artSize)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(themeColor)
                    }
                    
                    Text(item.title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(item.artist)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    AudioSpectrumView(isPlaying: mediaProvider.isPlaying, color: themeColor)
                        .frame(width: 16, height: 11)
                }
                .padding(.horizontal, 10)
                .frame(width: 260, height: height)
            } else {
                Color.clear
                    .frame(width: 160, height: height)
            }
        }
    }
}
