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
    
    var body: some View {
        let height = display.physicalNotchHeight
        let artSize = max(14, height - 12)
        
        HStack(spacing: 0) {
            if mediaProvider.isAvailable, let item = mediaProvider.currentItem {
                // Left Wing: Album Artwork or Music Note Icon
                HStack {
                    if let artwork = mediaProvider.artworkImage {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: artSize, height: artSize)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: artSize, height: artSize)
                    }
                }
                .frame(width: artSize + 6, alignment: .leading)
                .padding(.leading, 4)
                
                // Center Spacer matching camera cutout on notch displays, or Marquee on non-notch displays
                if display.hasNotch {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: max(0, display.physicalNotchWidth - 6))
                } else {
                    HStack(spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        Text(item.artist)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                }
                
                // Right Wing: Animated Audio Visualizer Equalizer Bars
                HStack {
                    AudioSpectrumView(isPlaying: mediaProvider.isPlaying, color: .white)
                        .frame(width: 18, height: 12)
                }
                .frame(width: artSize + 6, alignment: .trailing)
                .padding(.trailing, 4)
            } else {
                // Empty idle notch
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxHeight: height, alignment: .center)
    }
}
