//
//  CollapsedNotchView.swift
//  notcher
//

import SwiftUI

struct CollapsedNotchView: View {
    var stateMachine: NotchStateMachine
    var display: DisplayDescriptor
    var configuration: NotchConfiguration
    
    @State private var mediaProvider = SystemMediaProvider.shared
    
    var body: some View {
        HStack(spacing: 8) {
            if mediaProvider.isPlaying, let item = mediaProvider.currentItem {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.green)
                    Text(item.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.leading, 10)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.green)
                            .frame(width: 2, height: CGFloat(5 + ((i * 3) % 6)))
                    }
                }
                .padding(.trailing, 10)
            } else {
                Rectangle()
                    .fill(Color.clear)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
