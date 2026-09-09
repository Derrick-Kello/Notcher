//
//  NotchRootView.swift
//  notcher
//

import SwiftUI

struct NotchRootView: View {
    var stateMachine: NotchStateMachine
    var display: DisplayDescriptor
    var widgetRegistry: WidgetRegistry
    
    private var settings: SettingsModel { AppEnvironment.shared.settings }
    private var configuration: NotchConfiguration { settings.configuration }
    @State private var mediaProvider = SystemMediaProvider.shared
    
    @State private var hoverTask: Task<Void, Never>?
    @State private var isHovering: Bool = false
    
    private let openAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    private let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)
    private let animationSpring = Animation.interactiveSpring(response: 0.38, dampingFraction: 0.8, blendDuration: 0)
    
    private var isExpanded: Bool {
        switch stateMachine.state {
        case .expanded, .pinned, .expanding, .temporarilyExpanded:
            return true
        default:
            return false
        }
    }
    
    private var hasActiveMedia: Bool {
        mediaProvider.isAvailable && mediaProvider.currentItem != nil
    }
    
    private var topCornerRadius: CGFloat {
        isExpanded ? 19 : 6
    }
    
    private var bottomCornerRadius: CGFloat {
        isExpanded ? 24 : 14
    }
    
    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
    }
    
    private var currentNotchWidth: CGFloat {
        if isExpanded {
            return DisplayGeometry.openNotchSize.width
        } else {
            if display.hasNotch {
                return hasActiveMedia ? (display.physicalNotchWidth + 72) : display.physicalNotchWidth
            } else {
                return hasActiveMedia ? 260 : 160
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                notchContent
                    .frame(
                        width: currentNotchWidth,
                        height: isExpanded ? DisplayGeometry.openNotchSize.height : display.physicalNotchHeight,
                        alignment: .top
                    )
                    .background(Color.black)
                    .clipShape(currentNotchShape)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 1)
                            .padding(.horizontal, topCornerRadius)
                    }
                    .shadow(
                        color: (isExpanded || isHovering) ? Color.black.opacity(0.7) : Color.clear,
                        radius: isExpanded ? 6 : 4
                    )
                    .contentShape(currentNotchShape)
                    .animation(isExpanded ? openAnimation : closeAnimation, value: isExpanded)
                    .animation(animationSpring, value: currentNotchWidth)
            }
        }
        .frame(maxWidth: DisplayGeometry.windowSize.width, maxHeight: DisplayGeometry.windowSize.height, alignment: .top)
        .onReceive(NotificationCenter.default.publisher(for: .notchMouseEntered)) { _ in
            handleHover(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .notchMouseExited)) { _ in
            handleHover(false)
        }
    }
    
    @ViewBuilder
    private var notchContent: some View {
        if isExpanded {
            ExpandedNotchView(
                stateMachine: stateMachine,
                display: display,
                widgetRegistry: widgetRegistry,
                configuration: configuration
            )
            .transition(.opacity)
        } else {
            CollapsedNotchView(
                stateMachine: stateMachine,
                display: display,
                configuration: configuration
            )
            .contentShape(currentNotchShape)
            .onTapGesture {
                withAnimation(animationSpring) {
                    stateMachine.send(.expandRequested)
                }
            }
            .transition(.opacity)
        }
    }
    
    private func handleHover(_ hovering: Bool) {
        hoverTask?.cancel()
        
        if hovering {
            withAnimation(animationSpring) {
                isHovering = true
            }
            
            guard !isExpanded else { return }
            guard configuration.hoverEnabled else { return }
            
            hoverTask = Task {
                let delay = max(0.05, configuration.hoverDelay)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard !self.isExpanded, self.isHovering else { return }
                    withAnimation(self.openAnimation) {
                        self.stateMachine.send(.expandRequested)
                    }
                }
            }
        } else {
            withAnimation(animationSpring) {
                isHovering = false
            }
            
            hoverTask = Task {
                try? await Task.sleep(nanoseconds: 180_000_000)
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    if self.isExpanded && !self.isHovering && self.stateMachine.state != .pinned {
                        withAnimation(self.closeAnimation) {
                            self.stateMachine.send(.collapseRequested)
                        }
                    }
                }
            }
        }
    }
}
