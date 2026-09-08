//
//  HoverButton.swift
//  notcher
//

import SwiftUI

struct HoverButton: View {
    var icon: String
    var iconColor: Color = .white
    var size: CGFloat = 30
    var iconSize: CGFloat = 14
    var action: () -> Void
    
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isHovering ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                    .frame(width: size, height: size)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: iconSize, weight: .semibold))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

