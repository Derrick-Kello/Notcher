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
        let artSize = max(14, height - 14)
        
        HStack(spacing: 0) {
            if mediaProvider.isAvailable, let item = mediaProvider.currentItem {
                // Left Side: Album Artwork or Music Note Icon
                HStack {
                    if let artwork = mediaProvider.artworkImage {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: artSize, height: artSize)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: artSize, height: artSize)
                    }
                }
                .padding(.leading, 8)
                
                Spacer(minLength: 4)
                
                if !display.hasNotch {
                    // On external screens without a notch, show track title & artist
                    HStack(spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                        Text(item.artist)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 4)
                    
                    Spacer(minLength: 4)
                }
                
                // Right Side: Animated Audio Visualizer Equalizer Bars
                HStack {
                    AudioSpectrumView(isPlaying: mediaProvider.isPlaying, color: .white)
                        .frame(width: 16, height: 11)
                }
                .padding(.trailing, 8)
            } else {
                // Empty idle notch
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: height, alignment: .center)
    }
}
