# Notch App — Build Prompt

## Role

You are a senior macOS engineer specializing in Swift, SwiftUI, AppKit, Core Animation, media APIs, accessibility, and production desktop applications.

Build a polished native macOS notch companion app inspired by the interaction model of Boring Notch, but **do not copy its branding, source code, visual identity, or proprietary assets**. The goal is to create an original, production-quality product that turns the MacBook notch area into a contextual mini control center.

Reference research:
- Boring Notch repository: https://github.com/TheBoredTeam/boring.notch
- Apple `NSWindow.CollectionBehavior`: https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct
- Apple `NSPanel`: https://developer.apple.com/documentation/appkit/nspanel
- Apple `MenuBarExtra`: https://developer.apple.com/documentation/swiftui/menubarextra

## Product goal

Create an always-available notch UI that is almost invisible when idle and expands naturally when the user interacts with it.

Core interaction:

1. App launches as a menu-bar/background utility.
2. A compact black/dark notch capsule sits precisely around the MacBook camera/notch region.
3. Hovering over the notch expands it with a smooth spring animation.
4. Moving the pointer away collapses it after a short configurable delay.
5. Clicking can pin/expand the interface.
6. The expanded surface hosts modular widgets.
7. Widgets can react to system state and user actions.
8. The app must work across different MacBook display sizes, resolutions, Retina scales, and external displays.
9. The notch UI must not steal focus from the active application unless the user intentionally interacts with a control.
10. The application must remain lightweight and battery-conscious.

## MVP features

### 1. Notch shell

Implement:

- Borderless AppKit `NSPanel`/`NSWindow`.
- Transparent background.
- No title bar.
- Rounded notch-compatible shape.
- Dynamic width and height.
- Window level appropriate for a utility overlay.
- Non-activating interaction where appropriate.
- Correct behavior across Spaces and full-screen applications.
- Screen/display-aware positioning.
- Automatic repositioning when display configuration changes.
- Retina-aware coordinates.
- Safe handling for MacBooks with a physical notch.
- Graceful fallback on non-notch Macs.

The notch should visually feel attached to the menu bar rather than like a normal floating window.

### 2. State machine

Create an explicit UI state machine:

- `collapsed`
- `hovering`
- `expanding`
- `expanded`
- `pinned`
- `collapsing`
- `temporarilyExpanded`

Transitions must be deterministic and testable.

Inputs include:

- mouse enter
- mouse exit
- click
- escape
- global shortcut
- widget action
- timeout
- display change
- application activation change

Do not scatter animation state across unrelated SwiftUI views.

### 3. Widget system

Design the notch as a host for modular widgets.

Initial widgets:

- Now Playing
- Music playback controls
- Battery
- Current time
- Calendar/events
- Clipboard/recent item preview
- File shelf/drop zone
- System status
- Quick actions

Every widget should conform to a common protocol/model so additional widgets can be added without rewriting the shell.

Example conceptual interface:

```swift
protocol NotchWidget {
    var id: String { get }
    var title: String { get }
    var priority: Int { get }

    func collapsedView() -> AnyView
    func expandedView() -> AnyView
}
```

Prefer a SwiftUI-first implementation while keeping AppKit responsibilities in the window/controller layer.

### 4. Now Playing

Implement a provider abstraction:

```swift
protocol NowPlayingProvider {
    var currentItem: NowPlayingItem? { get }
    var isPlaying: Bool { get }

    func playPause()
    func next()
    func previous()
}
```

The provider should be replaceable so the app is not tightly coupled to one media implementation.

Support:

- artwork
- title
- artist
- album
- playback state
- play/pause
- previous
- next
- progress
- elapsed/remaining time where available

Avoid polling aggressively. Prefer event-driven updates.

### 5. Shelf

Create a temporary file shelf inspired by the concept of a notch drop area.

Behavior:

- Drag files onto the notch.
- Expand automatically during drag-over.
- Show thumbnails/items.
- Keep dropped items temporarily available.
- Allow dragging items back out.
- Allow opening/revealing items.
- Allow removing individual items.
- Persist only when explicitly configured.
- Never silently upload files to a server.

Use native macOS drag-and-drop APIs.

### 6. Menu bar control

Use a SwiftUI `MenuBarExtra` or an AppKit status item where appropriate.

Menu options:

- Open/expand notch
- Pin notch
- Enable/disable hover expansion
- Widget configuration
- Appearance
- Shortcuts
- Launch at login
- Check for updates
- About
- Quit

The menu bar is the configuration/control plane; the notch is the primary interaction surface.

### 7. Settings

Create a native macOS settings window.

Sections:

- General
- Notch
- Widgets
- Appearance
- Shortcuts
- Shelf
- Privacy
- Advanced

Settings should be persisted with `UserDefaults` / `@AppStorage` for simple preferences and a dedicated settings model for complex configuration.

### 8. Keyboard shortcuts

Provide configurable shortcuts for:

- Toggle notch
- Expand/pin
- Play/pause
- Open shelf
- Open settings

Do not require Accessibility permissions for basic app operation.

Only request privileged permissions when a feature genuinely requires them, and explain why.

## UX requirements

The interface should feel:

- native to macOS
- minimal
- extremely smooth
- responsive
- premium
- quiet
- contextual
- keyboard-friendly
- mouse-friendly
- accessible

Avoid:

- excessive gradients
- unnecessary glass effects
- huge controls
- permanent overlays
- intrusive notifications
- constant animations
- CPU-heavy visualizers when nothing is playing

Use SwiftUI animation and Core Animation where they improve performance.

## Window behavior requirements

The notch window must:

- be borderless
- have no standard window chrome
- use transparent visual material/background where appropriate
- avoid becoming the user's active application simply because it is hovered
- correctly handle mouse events
- support hit testing only over interactive regions
- support click-through/non-interactive regions where needed
- maintain correct z-order
- handle Spaces
- handle full-screen apps
- respond to display changes
- handle sleep/wake
- handle display connect/disconnect
- handle resolution/scale changes
- handle menu bar relocation where relevant

Do not hard-code one MacBook resolution.

Use `NSScreen` and display information dynamically.

## Architecture rules

Use the architecture in `architecture.md`.

Important separation:

- AppKit owns windowing, display geometry, global event integration, lifecycle, and system integration.
- SwiftUI owns presentation and widget UI.
- Domain models must not depend directly on AppKit.
- Providers abstract external/system data.
- Managers coordinate long-lived system services.
- The notch window controller must not contain business logic.
- Widgets must not directly manipulate the notch window.
- Settings must be dependency-injected where practical.
- Services should be protocol-based to make testing possible.

## Performance

Target:

- negligible idle CPU
- low memory footprint
- no unnecessary timers
- event-driven media/state updates
- animations only during interaction
- no continuous rendering when collapsed
- efficient artwork/image caching
- no unnecessary network requests
- no background server unless required

Create a lightweight diagnostics layer that can expose:

- current widget
- current state
- frame rate during animation
- provider update frequency
- memory usage
- CPU usage
- event counts

Do not ship verbose logging enabled by default.

## Accessibility

Support:

- VoiceOver labels
- keyboard navigation
- sufficient contrast
- Reduce Motion
- Increase Contrast
- Dynamic Type where applicable
- clear accessibility descriptions for controls
- accessible alternatives for hover-only interactions

If Reduce Motion is enabled, replace large spring animations with short fades/scales.

## Privacy

The app should be local-first.

Do not collect:

- files
- clipboard contents
- media metadata
- screen contents
- browsing history

unless the user explicitly enables a feature that needs the information.

No telemetry in MVP.

Clearly document any macOS permissions.

## Project structure

Use a native Xcode project with Swift Package Manager only when a dependency is justified.

Prefer:

```text
NotchApp/
├── App/
├── Core/
│   ├── Models/
│   ├── Protocols/
│   ├── State/
│   └── Utilities/
├── Windowing/
├── Notch/
│   ├── Views/
│   ├── Controllers/
│   ├── Layout/
│   └── Animation/
├── Widgets/
│   ├── Core/
│   ├── NowPlaying/
│   ├── Battery/
│   ├── Calendar/
│   ├── Shelf/
│   └── SystemStatus/
├── Providers/
├── Services/
├── Managers/
├── MenuBar/
├── Settings/
├── Accessibility/
├── Resources/
└── Tests/
```

## Implementation phases

### Phase 1 — Foundation

Build:

- macOS app lifecycle
- menu bar item
- notch window
- display detection
- dynamic positioning
- collapsed/expanded state machine
- hover detection
- animations
- settings persistence

### Phase 2 — Widget framework

Build:

- widget protocol
- widget registry
- widget layout engine
- widget lifecycle
- configuration
- priority/order system

### Phase 3 — Now Playing

Build:

- provider abstraction
- current media model
- playback controls
- artwork
- progress

### Phase 4 — Shelf

Build:

- drag detection
- file items
- previews
- drag-out
- persistence rules

### Phase 5 — System widgets

Add:

- battery
- calendar
- time
- system status

### Phase 6 — Polish

Add:

- accessibility
- Reduce Motion
- display edge cases
- full-screen behavior
- performance optimization
- crash/error handling
- updater
- code signing/notarization readiness

## Testing requirements

Write tests for:

- state transitions
- display geometry calculations
- widget registration
- widget ordering
- settings persistence
- provider state changes
- shelf item lifecycle

Manually verify:

- internal MacBook display
- external display
- different resolutions/scales
- full-screen applications
- multiple Spaces
- Stage Manager
- sleep/wake
- display connect/disconnect
- dark/light mode
- Reduce Motion
- VoiceOver
- keyboard-only navigation

## Engineering constraints

- Swift 6 where compatible with the selected macOS deployment target.
- SwiftUI for UI.
- AppKit for advanced window management.
- Avoid Electron/Tauri for the notch overlay.
- Avoid private APIs unless absolutely unavoidable and clearly isolated.
- Do not depend on undocumented screen geometry assumptions.
- Do not copy Boring Notch source code.
- Do not copy its branding/assets.
- Keep the implementation independently maintainable.

## Definition of done

The app is considered MVP-complete when:

1. It launches as a background/menu-bar macOS utility.
2. The notch is correctly positioned on supported MacBook displays.
3. Hover expands the notch smoothly.
4. Leaving the area collapses it reliably.
5. Clicking/pinning works.
6. The UI does not unnecessarily steal focus.
7. The app behaves correctly in full-screen apps and Spaces.
8. At least three widgets work through the common widget architecture.
9. Now Playing works through a provider abstraction.
10. Settings persist across launches.
11. Accessibility and Reduce Motion are supported.
12. No hard-coded display resolution is used.
13. Unit tests cover core state/geometry/widget logic.
14. The application is ready for code signing, notarization, DMG packaging, and distribution.

## Development style

Before implementing a feature:

1. Inspect the existing architecture.
2. Identify the correct layer.
3. Add or update a protocol if the feature represents an external/system dependency.
4. Implement the smallest coherent change.
5. Write tests for deterministic logic.
6. Run the app and verify the actual macOS behavior.
7. Do not work around AppKit behavior with arbitrary delays unless the delay is part of the UX state machine.
8. Keep windowing code centralized.
9. Prefer composable SwiftUI views.
10. Document any macOS-specific workaround.

The final result should feel like a native macOS utility rather than a web application placed over the menu bar.
