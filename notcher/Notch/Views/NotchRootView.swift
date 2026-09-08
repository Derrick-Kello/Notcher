//
//  NotchRootView.swift
//  notcher
//

import SwiftUI

struct NotchRootView: View {
    var stateMachine: NotchStateMachine
    var display: DisplayDescriptor
    var widgetRegistry: WidgetRegistry
    var configuration: NotchConfiguration
    
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
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                let mainLayout = notchContent
                    .frame(alignment: .top)
                    .padding(.horizontal, isExpanded ? 19 : 14)
                    .padding([.horizontal, .bottom], isExpanded ? 12 : 0)
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
                
                mainLayout
                    .frame(height: isExpanded ? DisplayGeometry.openNotchSize.height : nil)
                    .animation(isExpanded ? openAnimation : closeAnimation, value: isExpanded)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        handleHover(hovering)
                    }
                    .onTapGesture {
                        handleTap()
                    }
            }
        }
        .frame(maxWidth: DisplayGeometry.windowSize.width, maxHeight: DisplayGeometry.windowSize.height, alignment: .top)
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
            let width = display.hasNotch
                ? max(140, display.physicalNotchWidth - 20)
                : 165
            let height = display.physicalNotchHeight
            
            CollapsedNotchView(
                stateMachine: stateMachine,
                display: display,
                configuration: configuration
            )
            .frame(width: width, height: height)
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
                    self.stateMachine.send(.toggleRequested)
                }
            }
        } else {
            hoverTask = Task {
                try? await Task.sleep(nanoseconds: 120_000_000)
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    withAnimation(self.animationSpring) {
                        self.isHovering = false
                    }
                    
                    if self.isExpanded && self.stateMachine.state != .pinned {
                        self.stateMachine.send(.toggleRequested)
                    }
                }
            }
        }
    }
    
    private func handleTap() {
        withAnimation(animationSpring) {
            stateMachine.send(.toggleRequested)
        }
    }
}
