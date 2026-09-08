//
//  NotchRootView.swift
//  notcher
//

import SwiftUI

struct NotchRootView: View {
    var stateMachine: NotchStateMachine
    var displayManager: DisplayManager
    var widgetRegistry: WidgetRegistry
    var configuration: NotchConfiguration
    
    @State private var hoverTask: Task<Void, Never>?
    @State private var isHovering: Bool = false
    
    // Smooth interactive spring matching BoringNotch
    private let springAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    
    private var isExpanded: Bool {
        switch stateMachine.state {
        case .expanded, .pinned, .expanding, .temporarilyExpanded:
            return true
        default:
            return false
        }
    }
    
    var body: some View {
        let display = displayManager.activeDisplay ?? displayManager.resolveActiveDisplay()
        let closedSize = display != nil
            ? DisplayGeometry.closedNotchSize(for: display!, config: configuration)
            : CGSize(width: 185, height: 32)
        
        let openSize = DisplayGeometry.openNotchSize
        let currentWidth = isExpanded ? openSize.width : closedSize.width
        let currentHeight = isExpanded ? openSize.height : closedSize.height
        
        let topRadius = isExpanded ? DisplayGeometry.openCornerRadii.top : DisplayGeometry.closedCornerRadii.top
        let bottomRadius = isExpanded ? DisplayGeometry.openCornerRadii.bottom : DisplayGeometry.closedCornerRadii.bottom
        
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    if isExpanded {
                        ExpandedNotchView(
                            stateMachine: stateMachine,
                            widgetRegistry: widgetRegistry,
                            configuration: configuration
                        )
                        .transition(.opacity)
                    } else {
                        CollapsedNotchView(
                            stateMachine: stateMachine,
                            configuration: configuration
                        )
                        .transition(.opacity)
                    }
                }
                .frame(width: currentWidth, height: currentHeight, alignment: .top)
                .background(Color.black)
                .clipShape(NotchShape(topCornerRadius: topRadius, bottomCornerRadius: bottomRadius))
                .shadow(color: isExpanded ? Color.black.opacity(0.6) : (isHovering ? Color.black.opacity(0.3) : Color.clear), radius: isExpanded ? 10 : 4, y: isExpanded ? 4 : 1)
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
        .animation(springAnimation, value: isExpanded)
    }
    
    private func handleHover(_ hovering: Bool) {
        hoverTask?.cancel()
        isHovering = hovering
        
        if hovering {
            guard !isExpanded else { return }
            guard configuration.hoverEnabled else { return }
            
            hoverTask = Task {
                let delay = max(0.08, configuration.hoverDelay)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard !self.isExpanded else { return }
                    self.stateMachine.send(.toggleRequested)
                }
            }
        } else {
            guard isExpanded, stateMachine.state != .pinned else { return }
            
            hoverTask = Task {
                try? await Task.sleep(nanoseconds: 120_000_000) // 120ms grace period
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard self.isExpanded, self.stateMachine.state != .pinned else { return }
                    self.stateMachine.send(.toggleRequested)
                }
            }
        }
    }
    
    private func handleTap() {
        stateMachine.send(.toggleRequested)
    }
}
