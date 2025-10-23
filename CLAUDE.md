# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Home Assistant Toolbar is a SwiftUI-based multi-platform application (macOS and iOS) that displays real-time Home Assistant sensor data. On macOS it runs as a menu bar application, while on iOS it's a standard app.

## Build Commands

```bash
# Build the project
xcodebuild -scheme HomeAssistantToolbar -configuration Debug build

# Build for release
xcodebuild -scheme HomeAssistantToolbar -configuration Release build

# Run tests
xcodebuild test -scheme HomeAssistantToolbar

# Open in Xcode
open HomeAssistantToolbar.xcodeproj
```

## Architecture

### Core Components

**HomeAssistantClient** (`NewNetworking/HomeAssistantClient.swift`)
- Swift 6 `actor` that owns both REST and WebSocket access to Home Assistant
- Authenticates, subscribes to `state_changed`, pings every 10 seconds, and publishes events via `AsyncStream<ClientEvent>`
- Explicit connection-state machine (`connecting → authenticated → subscribed → disconnected`)

**HomeAssistantService** (`Services/HomeAssistantService.swift`)
- `@MainActor` bridge that instantiates the actor, forwards events into `MonitoredSensors`, and mirrors connection state/ping counts for the UI
- Handles initial REST hydration, structured reconnects on network loss, and exposes an observable API for SwiftUI

**MonitoredSensors** (`Model/MonitoredSensors.swift`)
- Singleton `ObservableObject` that holds current sensor state
- Published properties for temperature, wind speed, rain amount, and event count
- All updates are `@MainActor` to ensure thread safety
- Shared between HomeAssistantService and UI layers
- Persists data to shared storage and triggers widget timeline reloads

**SharedSensorStorage** (`Model/SharedSensorStorage.swift`)
- Static namespace over App Group storage shared by app and widget
- Uses `UserDefaults(suiteName: "group.io.opsnlops.HomeAssistantToolbar")` under the hood
- Provides snapshot/ accessor helpers (`getSensorSnapshot()`) for widget timelines

**HomeAssistantToolbarApp** (`HomeAssistantToolbarApp.swift`)
- Main app entry point with platform-specific UI:
  - **macOS**: `MenuBarExtra` showing temperature in menu bar with dropdown details
  - **iOS**: Standard `WindowGroup` with `TopContentView`
- Loads credentials from `SimpleKeychain` on startup
- Initiates WebSocket connection if credentials are configured

### Data Flow

1. **Authentication**: Credentials stored in `SimpleKeychain` (service: `io.opsnlops.HomeAssistantToolbar`)
2. **Connection**: `HomeAssistantService` calls the actor’s `connect()`, which authenticates and subscribes to `state_changed`
3. **Initial State**: After auth, the service issues REST fetches (`/api/states/…`) for each configured sensor
4. **Live Updates**: WebSocket events update `MonitoredSensors` which triggers:
   - SwiftUI view updates via `@Published` properties
   - Shared storage writes via `SharedSensorStorage`
   - Widget timeline reloads via `WidgetCenter.shared.reloadAllTimelines()`
5. **Reconnection**: The service monitors connection state and schedules reconnect attempts after network failures or lifecycle transitions

### Widget Architecture

**HomeAssistantWidget** (`HomeAssistantWidget/`)
- Separate Widget Extension target using WidgetKit (iOS 26 / macOS 26)
- Implements `AppIntentTimelineProvider` for timeline management
- Reads sensor data from shared App Group storage
- Supports multiple widget families:
  - **iOS**: Small, Medium, Large, Circular (Lock Screen), Rectangular (Lock Screen), Inline (Lock Screen), CarPlay
  - **macOS**: Small, Medium, Large, Extra Large
- Uses iOS 26 **Glass Presentation System** with `.containerBackground(.fill.tertiary, for: .widget)`
- User-configurable display styles via `SensorConfigurationIntent` (App Intents)
- Timeline refreshes every 15 minutes or when app updates sensor data
- **CarPlay Support**: Dedicated `HomeAssistantCarPlayWidget` with optimized rectangular layout for vehicle dashboard

### Configuration

App uses `@AppStorage` for settings:
- `serverPort`: Home Assistant server port (default: 443)
- `serverUseTLS`: Whether to use TLS (default: true)
- `outsideTemperatureEntity`: Entity ID for temperature sensor
- `windSpeedEntity`: Entity ID for wind speed sensor
- `rainAmountEntity`: Entity ID for rain sensor

Credentials are stored separately in keychain:
- `authToken`: Home Assistant long-lived access token
- `externalHostname`: Home Assistant server hostname

### Platform-Specific Code

The app uses `#if os(macOS)` / `#elseif os(iOS)` extensively for platform differences:
- macOS uses `NSWorkspace` notifications and `MenuBarExtra`
- iOS uses `UIApplication` notifications and standard SwiftUI views
- `HomeAssistantService` centralises lifecycle handling; the actor itself is platform-agnostic

### Important Implementation Details

- **Singleton Pattern**: `HomeAssistantService` and `MonitoredSensors` expose shared instances for convenience
- **Pure Swift**: Lifecycle observers and API clients are closure-based Swift; no `@objc` selectors required
- **Memory Safety**: Observers/tasks capture `[weak self]` and are cancelled on teardown
- **Thread Safety**: UI/state updates happen on the main actor; networking is actor-isolated
- **Logging**: Uses `OSLog` with subsystem `io.opsnlops.HomeAssistantToolbar`
- **App Groups**: Required for widget data sharing - `group.io.opsnlops.HomeAssistantToolbar` must be configured in both main app and widget extension entitlements

### Widget Extension Setup

The widget extension requires manual Xcode configuration:

1. Add Widget Extension target to project (File → New → Target → Widget Extension)
2. Name: `HomeAssistantWidget`
3. Include Configuration Intent: Yes
4. Add App Group capability to both main app and widget targets
5. Configure App Group: `group.io.opsnlops.HomeAssistantToolbar`
6. Add `SharedSensorStorage.swift` and `SensorSnapshot` to both targets (shared files)
7. Widget files are in `HomeAssistantWidget/` directory
