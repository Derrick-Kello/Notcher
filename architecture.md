# Notch App — Architecture

## 1. Overview

This project is a native macOS utility that turns the MacBook notch/menu-bar region into a contextual interaction surface.

The architecture deliberately combines:

- **SwiftUI** for UI composition and widget presentation.
- **AppKit** for window lifecycle, panel behavior, display geometry, mouse/event integration, and macOS-specific behavior.
- **Protocol-based providers/services** for system integrations.
- **A centralized state machine** for notch interaction.
- **A widget registry/layout engine** for extensibility.

Boring Notch demonstrates the product category and several useful concepts, including a notch overlay, music controls, calendar, shelf functionality, HUD-style interactions, and modular project organization. Its public repository currently separates the main app, media adapter, updater, helper, and several feature-oriented directories. This project should take the architectural lessons without copying its implementation or visual identity.

Apple documents `NSPanel` as an auxiliary window type and exposes window levels and collection behaviors for controlling how windows participate in Spaces, Mission Control, Stage Manager, and full-screen environments. `MenuBarExtra` provides the native SwiftUI menu-bar integration.

---

# 2. High-level architecture

```text
                         ┌─────────────────────┐
                         │      macOS OS       │
                         │                     │
                         │ Screens / Spaces    │
                         │ Media / Battery     │
                         │ Calendar / Files     │
                         │ Input / Accessibility│
                         └──────────┬──────────┘
                                    │
                 ┌──────────────────┴──────────────────┐
                 │                                     │
          ┌──────▼──────┐                       ┌──────▼──────┐
          │   Providers │                       │   Services  │
          │             │                       │             │
          │ Now Playing │                       │ Settings    │
          │ Battery     │                       │ Shortcuts   │
          │ Calendar    │                       │ File Shelf  │
          │ Display     │                       │ Updater     │
          └──────┬──────┘                       └──────┬──────┘
                 │                                     │
                 └──────────────────┬──────────────────┘
                                    │
                          ┌─────────▼─────────┐
                          │   Domain/Core     │
                          │                   │
                          │ Models            │
                          │ State Machine     │
                          │ Widget Registry   │
                          │ Configuration     │
                          └─────────┬─────────┘
                                    │
                    ┌───────────────┴────────────────┐
                    │                                │
             ┌──────▼──────┐                  ┌──────▼──────┐
             │  Windowing  │                  │   Widgets   │
             │             │                  │             │
             │ NSPanel     │                  │ Now Playing │
             │ Positioning │                  │ Battery     │
             │ Hit Testing │                  │ Calendar    │
             │ Spaces      │                  │ Shelf       │
             └──────┬──────┘                  │ Status      │
                    │                         └──────┬──────┘
                    │                                │
                    └───────────────┬────────────────┘
                                    │
                             ┌──────▼──────┐
                             │   SwiftUI   │
                             │ Presentation│
                             └─────────────┘
```

---

# 3. Architectural principles

## 3.1 AppKit at the system boundary

Do not attempt to make the notch overlay a normal SwiftUI `WindowGroup`.

The notch requires control over:

- window style
- window level
- activation behavior
- screen coordinates
- collection behavior
- hit testing
- mouse tracking
- Spaces/full-screen behavior
- display changes

Those concerns belong in AppKit.

SwiftUI should receive state from the domain layer and render the content.

---

## 3.2 SwiftUI for presentation

SwiftUI owns:

- widget views
- layouts
- controls
- animations
- settings UI
- menu-bar content
- accessibility labels

SwiftUI views should not:

- directly reposition the `NSPanel`
- access `NSScreen` repeatedly
- manage global event monitors
- own media provider lifecycles
- modify window levels

---

## 3.3 Domain logic is framework-light

The core state machine and models should be testable without creating a window.

Avoid:

```swift
if mouseEntered {
    notchWindow.orderFront(...)
}
```

inside SwiftUI views.

Prefer:

```text
Input event
    ↓
NotchInteractionController
    ↓
NotchStateMachine
    ↓
NotchState
    ↓
NotchWindowController + SwiftUI
```

---

# 4. Directory structure

```text
NotchApp/
│
├── App/
│   ├── NotchApp.swift
│   ├── AppDelegate.swift
│   └── AppEnvironment.swift
│
├── Core/
│   ├── Models/
│   │   ├── NotchState.swift
│   │   ├── NotchConfiguration.swift
│   │   ├── DisplayDescriptor.swift
│   │   ├── WidgetDescriptor.swift
│   │   └── NowPlayingItem.swift
│   │
│   ├── Protocols/
│   │   ├── NotchWidget.swift
│   │   ├── NowPlayingProvider.swift
│   │   ├── BatteryProvider.swift
│   │   ├── CalendarProvider.swift
│   │   └── SettingsStore.swift
│   │
│   ├── State/
│   │   ├── NotchStateMachine.swift
│   │   ├── NotchEvent.swift
│   │   └── NotchReducer.swift
│   │
│   └── Utilities/
│
├── Windowing/
│   ├── NotchPanel.swift
│   ├── NotchWindowController.swift
│   ├── NotchWindowCoordinator.swift
│   ├── DisplayManager.swift
│   ├── DisplayGeometry.swift
│   ├── MouseTrackingManager.swift
│   └── WindowBehavior.swift
│
├── Notch/
│   ├── Views/
│   │   ├── NotchRootView.swift
│   │   ├── CollapsedNotchView.swift
│   │   └── ExpandedNotchView.swift
│   │
│   ├── Layout/
│   │   ├── NotchLayoutEngine.swift
│   │   └── WidgetLayoutEngine.swift
│   │
│   └── Animation/
│       └── NotchAnimation.swift
│
├── Widgets/
│   ├── Core/
│   │   ├── WidgetRegistry.swift
│   │   ├── WidgetHost.swift
│   │   └── WidgetContext.swift
│   │
│   ├── NowPlaying/
│   ├── Battery/
│   ├── Calendar/
│   ├── Shelf/
│   └── SystemStatus/
│
├── Providers/
│   ├── Media/
│   ├── Battery/
│   ├── Calendar/
│   └── System/
│
├── Services/
│   ├── Settings/
│   ├── Shelf/
│   ├── Shortcuts/
│   ├── LaunchAtLogin/
│   └── Updates/
│
├── MenuBar/
│   ├── MenuBarController.swift
│   └── MenuBarView.swift
│
├── Settings/
│   ├── SettingsView.swift
│   ├── GeneralSettingsView.swift
│   ├── WidgetSettingsView.swift
│   └── SettingsModel.swift
│
├── Accessibility/
│
├── Resources/
│
└── Tests/
    ├── CoreTests/
    ├── WindowingTests/
    ├── WidgetTests/
    └── ProviderTests/
```

---

# 5. App lifecycle

```text
Application launch
       │
       ▼
Create AppEnvironment
       │
       ├── SettingsStore
       ├── ProviderContainer
       ├── WidgetRegistry
       ├── DisplayManager
       └── NotchStateMachine
       │
       ▼
Create MenuBarController
       │
       ▼
Create NotchWindowController
       │
       ▼
Resolve active display
       │
       ▼
Calculate notch geometry
       │
       ▼
Position panel
       │
       ▼
Install tracking/event monitors
       │
       ▼
Ready
```

The app should remain resident as a menu-bar utility.

If using `MenuBarExtra`, configure the app as a menu-bar-only utility when appropriate. Apple documents `LSUIElement` for applications that should not appear in the Dock/application switcher.

---

# 6. Notch window architecture

## 6.1 `NotchPanel`

Subclass `NSPanel`.

Responsibilities:

- configure style mask
- configure transparency
- configure level
- configure collection behavior
- control activation behavior
- override hit testing if necessary
- manage shadow/background
- expose safe interaction methods

Conceptual configuration:

```swift
final class NotchPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .borderless,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
    }
}
```

The exact window-level and collection behavior should be tested against full-screen apps and Spaces rather than blindly copied from another implementation.

Apple's `NSWindow.CollectionBehavior` provides explicit behaviors for Spaces, Stage Manager, Mission Control, and full-screen environments. In particular, `fullScreenAuxiliary` allows an auxiliary window to display alongside a full-screen window.

---

# 7. Display geometry

Never assume:

```swift
screen.frame.width == 3024
```

or a fixed notch width.

Instead create:

```swift
struct DisplayDescriptor {
    let screen: NSScreen
    let frame: CGRect
    let visibleFrame: CGRect
    let backingScaleFactor: CGFloat
    let safeArea: NSEdgeInsets
}
```

`DisplayManager` listens for:

- screen parameters changing
- screen connection/disconnection
- application activation changes where relevant

On any relevant change:

```text
Display event
    ↓
DisplayManager
    ↓
DisplayDescriptor
    ↓
NotchLayoutEngine
    ↓
NotchWindowController.updateFrame()
```

---

# 8. Notch positioning

The layout engine should calculate:

```swift
struct NotchFrame {
    let collapsed: CGRect
    let expanded: CGRect
}
```

Inputs:

```text
screen frame
visible frame
scale factor
menu bar geometry
notch availability
configuration
expanded content size
```

Do not hard-code physical pixel dimensions.

Prefer geometry measured in logical points.

For a supported physical notch, the overlay should align visually with the camera/notch region.

For displays without a physical notch:

- offer a configurable centered capsule mode, or
- disable the notch overlay and expose only the menu-bar utility.

---

# 9. State machine

Use an explicit state model.

```swift
enum NotchState {
    case collapsed
    case hovering
    case expanding
    case expanded
    case pinned
    case collapsing
    case temporarilyExpanded
}
```

Events:

```swift
enum NotchEvent {
    case mouseEntered
    case mouseExited
    case clicked
    case escapePressed
    case toggleRequested
    case pinRequested
    case unpinRequested
    case expansionCompleted
    case collapseCompleted
    case timeout
    case displayChanged
}
```

Transition table:

| Current | Event | Next |
|---|---|---|
| collapsed | mouseEntered | hovering |
| hovering | expansion trigger | expanding |
| expanding | expansionCompleted | expanded |
| expanded | mouseExited | collapsing |
| expanded | click | pinned |
| pinned | click | expanded |
| pinned | escape | collapsed |
| collapsing | mouseEntered | expanding |
| collapsing | collapseCompleted | collapsed |
| collapsed | toggleRequested | expanding |
| expanded | timeout | collapsing |

Timers should be owned by the state-machine/controller layer rather than SwiftUI views.

---

# 10. Interaction architecture

```text
Mouse / Keyboard / Shortcut
          │
          ▼
InteractionMonitor
          │
          ▼
NotchInteractionController
          │
          ▼
NotchStateMachine
          │
          ▼
NotchState
          │
     ┌────┴────┐
     ▼         ▼
Window       SwiftUI
Controller   ViewModel
```

The UI should be a projection of state.

---

# 11. Widget architecture

Each widget is a self-contained feature.

Conceptual protocol:

```swift
protocol NotchWidget {
    var id: String { get }
    var descriptor: WidgetDescriptor { get }

    func makeView(context: WidgetContext) -> AnyView
}
```

The widget should not know about `NSPanel`.

It can receive:

```swift
struct WidgetContext {
    let configuration: NotchConfiguration
    let services: ServiceContainer
}
```

---

# 12. Widget registry

```swift
final class WidgetRegistry {
    private var widgets: [String: any NotchWidget] = [:]

    func register(_ widget: any NotchWidget)
    func widget(id: String) -> (any NotchWidget)?
    func enabledWidgets() -> [any NotchWidget]
}
```

The registry controls discovery and configuration.

The layout engine controls presentation order.

---

# 13. Widget lifecycle

```text
Widget registered
      ↓
Enabled?
      ↓
Data provider available?
      ↓
Widget initialized
      ↓
Widget receives context
      ↓
SwiftUI renders widget
      ↓
Provider emits state
      ↓
Widget view updates
```

Widgets should subscribe to provider state rather than repeatedly querying system APIs.

---

# 14. Now Playing architecture

Use a provider abstraction:

```swift
protocol NowPlayingProvider: AnyObject {
    var state: NowPlayingState { get }

    func playPause()
    func next()
    func previous()
}
```

Implementation:

```text
NowPlayingWidget
       │
       ▼
NowPlayingProvider
       │
       ▼
Media Adapter
       │
       ▼
macOS media system
```

The media provider should be replaceable.

Boring Notch currently acknowledges `MediaRemoteAdapter` as the project used for Now Playing functionality on modern macOS versions. Treat that as a research lead, not a requirement to copy or directly depend on the Boring Notch implementation.

---

# 15. Shelf architecture

```text
Drag enters notch
       │
       ▼
ShelfController
       │
       ├── validate item
       ├── create ShelfItem
       └── update notch state
       │
       ▼
ShelfStore
       │
       ▼
ShelfWidget
```

Model:

```swift
struct ShelfItem: Identifiable {
    let id: UUID
    let url: URL
    let createdAt: Date
    let thumbnail: NSImage?
}
```

Security requirements:

- never execute dropped files automatically
- never upload files without explicit user action
- validate URLs
- avoid retaining security-scoped resources longer than needed
- clearly define persistence behavior

---

# 16. Settings architecture

Simple settings:

```text
@AppStorage
```

Complex settings:

```text
SettingsModel
    ↓
SettingsStore
    ↓
UserDefaults / Codable storage
```

Configuration model:

```swift
struct NotchConfiguration: Codable {
    var hoverEnabled: Bool
    var hoverDelay: TimeInterval
    var collapseDelay: TimeInterval
    var pinnedByDefault: Bool
    var enabledWidgets: [String]
    var widgetOrder: [String]
    var reducedEffects: Bool
}
```

Settings changes publish updates to the relevant controllers.

---

# 17. Menu bar architecture

```text
MenuBarController
      │
      ├── Toggle notch
      ├── Pin
      ├── Settings
      ├── Widget configuration
      └── Quit
```

Use SwiftUI `MenuBarExtra` when its lifecycle semantics fit the application. Apple documents it as the native SwiftUI scene for persistent menu-bar controls.

The menu-bar surface should not duplicate the notch UI.

---

# 18. Animation architecture

Animation state belongs to the notch layer.

Use:

- spring expansion
- spring collapse
- opacity
- scale
- width/height interpolation

Avoid animating the actual `NSPanel` with uncontrolled repeated `setFrame` calls from many views.

Preferred:

```text
State transition
      ↓
Animation coordinator
      ↓
target frame
      ↓
NSPanel frame animation
      +
SwiftUI content animation
```

The window frame and content animation should remain synchronized.

---

# 19. Hit testing

The panel should not behave like a giant invisible full-screen window.

Only the actual notch interaction region should receive mouse events.

Potential strategy:

```text
mouse location
     ↓
NotchPanel hitTest
     ↓
interactive region?
   /       \
 yes       no
  │         │
 handle    pass through
```

This is important to prevent the overlay from interfering with normal Mac interaction.

---

# 20. Full-screen and Spaces

Use `NSWindow.CollectionBehavior` deliberately.

Apple provides:

- `.canJoinAllSpaces`
- `.moveToActiveSpace`
- `.transient`
- `.fullScreenAuxiliary`
- `.fullScreenNone`
- `.auxiliary`

The exact combination should be validated through manual testing because the desired behavior differs between:

- normal windows
- full-screen applications
- Stage Manager
- multiple Spaces
- Mission Control

Do not blindly use every behavior flag simultaneously.

---

# 21. Permissions

MVP should minimize permissions.

Potential permission-sensitive features:

| Feature | Permission |
|---|---|
| Basic notch overlay | None |
| Menu bar item | None |
| Media controls | Depends on implementation/API |
| Calendar | Calendar permission |
| Reminders | Reminders permission |
| Accessibility/global keyboard monitoring | Accessibility permission |
| Screen capture | Screen Recording permission |
| File shelf | User-selected file access |

Request permissions only immediately before a feature needs them.

---

# 22. Error handling

System providers can fail.

Never allow:

```text
Media provider failure → notch crash
```

Instead:

```text
Provider error
    ↓
Provider state = unavailable
    ↓
Widget displays fallback
    ↓
Provider retries/reconnects when appropriate
```

The notch shell must remain functional even if every widget provider is unavailable.

---

# 23. Performance model

## Idle

When collapsed:

- no continuous animation
- no high-frequency timers
- no polling loop
- minimal provider work
- no expensive view rendering

## Expanded

When expanded:

- normal SwiftUI updates
- media progress updates only when necessary
- artwork cached
- animations limited to relevant views

## Shelf

Only generate thumbnails for visible/needed items.

---

# 24. Concurrency

Use Swift concurrency for asynchronous work.

Recommended:

```swift
@MainActor
final class NotchWindowController
```

UI/window mutations occur on the main actor.

Providers can perform asynchronous work off the main actor and publish results back to the UI layer.

Avoid uncontrolled `Task {}` creation from every view update.

Provider lifetimes should be managed by an application-level container.

---

# 25. Dependency container

Create:

```swift
@MainActor
final class AppEnvironment {
    let settings: SettingsStore
    let displayManager: DisplayManager
    let widgetRegistry: WidgetRegistry
    let nowPlaying: NowPlayingProvider
    let battery: BatteryProvider
    let shelf: ShelfService
    let notchStateMachine: NotchStateMachine
}
```

This avoids global singletons.

Small system adapters may use system APIs directly behind protocols.

---

# 26. Testing strategy

## Unit tests

Test without AppKit UI where possible:

- state transitions
- geometry calculations
- configuration
- widget registry
- widget ordering
- provider state transformations
- shelf lifecycle

## Integration tests

Test:

- provider → widget
- state machine → window controller
- settings → configuration
- display change → geometry update

## Manual macOS QA

Required:

- MacBook with notch
- non-notch Mac
- external monitor
- Retina scaling
- full-screen Safari
- full-screen video
- multiple Spaces
- Stage Manager
- Mission Control
- sleep/wake
- display reconnect
- dark/light mode
- Reduce Motion
- VoiceOver

---

# 27. Distribution

Production pipeline:

```text
Xcode
  ↓
Archive
  ↓
Developer ID signing
  ↓
Hardened Runtime
  ↓
Notarization
  ↓
Staple
  ↓
DMG
  ↓
Update feed
```

Prepare entitlements minimally.

Do not request capabilities that are not used.

---

# 28. Security model

The app is local-first.

Principles:

- no network dependency for core notch functionality
- no telemetry in MVP
- no silent file upload
- no unnecessary permissions
- no private API dependency unless unavoidable
- sanitize dropped URLs
- do not execute arbitrary dropped content
- minimize retained media/file metadata

---

# 29. Future extension architecture

The widget architecture should eventually support third-party/internal extensions.

Potential future model:

```text
Extension
 ├── metadata
 ├── configuration
 ├── widget
 ├── provider
 └── permissions
```

Do not implement a dynamic plugin system in MVP.

Instead, design the protocols so it can be added later.

---

# 30. Recommended implementation order

1. App lifecycle
2. Menu bar item
3. `NotchPanel`
4. Display geometry
5. Notch positioning
6. State machine
7. Hover/click interaction
8. SwiftUI notch shell
9. Widget registry
10. Now Playing
11. Battery
12. Shelf
13. Calendar
14. Settings
15. Keyboard shortcuts
16. Accessibility
17. Full-screen/Spaces hardening
18. Performance profiling
19. Signing/notarization
20. Distribution

---

# 31. Important architectural rule

The most important boundary in the entire application is:

```text
             SYSTEM
                │
       ┌────────┴────────┐
       │                 │
    AppKit            Providers
       │                 │
       └────────┬────────┘
                │
              CORE
                │
       ┌────────┴────────┐
       │                 │
   State Machine      Registry
       │                 │
       └────────┬────────┘
                │
             SWIFTUI
                │
             Widgets
```

**Do not allow the notch UI to become the architecture.**

The notch is only a presentation surface. The underlying product should be a modular macOS utility platform with a reusable state machine, provider layer, widget system, and display/windowing infrastructure.

---

# Sources / research notes

- Boring Notch public repository and README: https://github.com/TheBoredTeam/boring.notch
- Boring Notch main source tree: https://github.com/TheBoredTeam/boring.notch/tree/main/boringNotch
- Boring Notch media adapter directory: https://github.com/TheBoredTeam/boring.notch/tree/main/mediaremote-adapter
- Apple `NSPanel`: https://developer.apple.com/documentation/appkit/nspanel
- Apple `NSWindow.Level`: https://developer.apple.com/documentation/appkit/nswindow/level-swift.property
- Apple `NSWindow.CollectionBehavior`: https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct
- Apple `NSWindow.CollectionBehavior.fullScreenAuxiliary`: https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/fullscreenauxiliary
- Apple `NSWindow.CollectionBehavior.auxiliary`: https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/auxiliary
- Apple `NSWindow.StyleMask.nonactivatingPanel`: https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel
- Apple SwiftUI `MenuBarExtra`: https://developer.apple.com/documentation/swiftui/menubarextra

Research basis: Boring Notch currently documents macOS 14+ and Intel/Apple Silicon support, and its repository contains dedicated app, media adapter, updater, helper, provider, manager, component, sizing, and related feature directories. Apple’s current documentation confirms the AppKit window behaviors needed for auxiliary/full-screen/Spaces-aware utility overlays and SwiftUI’s native menu-bar integration.
