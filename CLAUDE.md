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

**WebSocketClient** (`WebSocketClient.swift`)
- Singleton that manages WebSocket connection to Home Assistant
- Handles authentication, message routing, and automatic reconnection
- Implements platform-specific lifecycle management:
  - **macOS**: Listens to `NSWorkspace` sleep/wake notifications
  - **iOS**: Listens to `UIApplication` background/foreground notifications
- Uses ping/pong mechanism to detect connection health (10-second interval)
- On connection loss or timeout, automatically reconnects after a 5-second delay
- All network operations are async/await based

**MonitoredSensors** (`Model/MonitoredSensors.swift`)
- Singleton `ObservableObject` that holds current sensor state
- Published properties for temperature, wind speed, rain amount, and event count
- All updates are `@MainActor` to ensure thread safety
- Shared between WebSocketClient and UI layers
- Persists data to shared storage and triggers widget timeline reloads

**SharedSensorStorage** (`Model/SharedSensorStorage.swift`)
- Manages App Group shared storage for sensor data
- Enables data sharing between main app and widget extension
- Uses `UserDefaults(suiteName: "group.io.opsnlops.HomeAssistantToolbar")`
- Provides snapshot of all sensor data for widget timelines

**HomeAssistantToolbarApp** (`HomeAssistantToolbarApp.swift`)
- Main app entry point with platform-specific UI:
  - **macOS**: `MenuBarExtra` showing temperature in menu bar with dropdown details
  - **iOS**: Standard `WindowGroup` with `TopContentView`
- Loads credentials from `SimpleKeychain` on startup
- Initiates WebSocket connection if credentials are configured

### Data Flow

1. **Authentication**: Credentials stored in `SimpleKeychain` (service: `io.opsnlops.HomeAssistantToolbar`)
2. **Connection**: WebSocketClient connects on app startup, authenticates, then subscribes to `state_changed` events
3. **Initial State**: After auth, REST API (`/api/states/`) fetches current values for all configured sensors
4. **Live Updates**: WebSocket events update `MonitoredSensors` which triggers:
   - SwiftUI view updates via `@Published` properties
   - Shared storage writes via `SharedSensorStorage`
   - Widget timeline reloads via `WidgetCenter.shared.reloadAllTimelines()`
5. **Reconnection**: Platform lifecycle events (sleep/wake, background/foreground) trigger automatic disconnect/reconnect

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
- WebSocketClient has separate notification handlers for each platform's lifecycle

### Important Implementation Details

- **Singleton Pattern**: Both `WebSocketClient` and `MonitoredSensors` use `.shared` singletons
- **Pure Swift**: All notification observers use closure-based Swift APIs, not `@objc` selectors
- **Memory Safety**: Observers use `[weak self]` and are cleaned up in `deinit`
- **Thread Safety**: All UI updates go through `@MainActor` or `DispatchQueue.main.async`
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
