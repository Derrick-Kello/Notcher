//
//  CollapsedNotchView.swift
//  notcher
//

import SwiftUI

struct CollapsedNotchView: View {
    var stateMachine: NotchStateMachine
    var configuration: NotchConfiguration
    
    @State private var mediaProvider = SystemMediaProvider.shared
    @State private var batteryProvider = SystemBatteryProvider.shared
    
    var body: some View {
        HStack(spacing: 8) {
            if mediaProvider.isPlaying, let item = mediaProvider.currentItem {
                // Live music activity
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                    
                    Text(item.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .frame(maxWidth: 90, alignment: .leading)
                }
                .padding(.leading, 12)
                
                Spacer()
                
                // Mini animated audio bars
                HStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.green)
                            .frame(width: 2.5, height: CGFloat(6 + ((i * 3) % 7)))
                    }
                }
                .padding(.trailing, 12)
            } else {
                // Subtle idle camera clearance
                Spacer()
                
                // Subtle indicator dot
                Circle()
                    .fill(Color.white.opacity(stateMachine.state == .hovering ? 0.3 : 0.08))
                    .frame(width: 4, height: 4)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
