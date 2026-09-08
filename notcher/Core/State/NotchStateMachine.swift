//
//  NotchStateMachine.swift
//  notcher
//
//  Created on 2026-09-08.
//

import Foundation
import Observation

@MainActor
@Observable
final class NotchStateMachine {
    private(set) var state: NotchState = .collapsed
    var configuration: NotchConfiguration
    
    private var hoverTask: Task<Void, Never>?
    private var collapseTask: Task<Void, Never>?
    
    init(configuration: NotchConfiguration) {
        self.configuration = configuration
    }
    
    func send(_ event: NotchEvent) {
        let (nextState, effect) = NotchReducer.reduce(state: state, event: event)
        
        #if DEBUG
        if nextState != state {
            print("[NotchStateMachine] Transition: \(state) + \(event) -> \(nextState) with effect \(effect)")
        }
        #endif
        
        self.state = nextState
        handle(effect: effect)
    }
    
    private func handle(effect: NotchSideEffect) {
        switch effect {
        case .startHoverTimer:
            hoverTask?.cancel()
            hoverTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(configuration.hoverDelay * 1_000_000_000))
                if !Task.isCancelled {
                    send(.timeout)
                }
            }
            
        case .cancelHoverTimer:
            hoverTask?.cancel()
            hoverTask = nil
            
        case .startCollapseTimer:
            collapseTask?.cancel()
            collapseTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(configuration.collapseDelay * 1_000_000_000))
                if !Task.isCancelled {
                    send(.timeout)
                }
            }
            
        case .cancelCollapseTimer:
            collapseTask?.cancel()
            collapseTask = nil
            
        case .animateExpansion, .animateCollapse, .none:
            // These effects are intended to be observed and acted upon by the view layer.
            // When an expansion or collapse animation finishes, the view should send
            // `expansionCompleted` or `collapseCompleted` events respectively.
            break
        }
    }
}
