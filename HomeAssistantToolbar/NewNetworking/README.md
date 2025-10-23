# HomeAssistantClient (Swift 6, Strict Concurrency)

This directory hosts the new concurrency-safe Home Assistant networking stack. The implementation embraces Swift 6 strict-concurrency rules:

- `HomeAssistantClient` is an `actor` that owns all mutable state for both REST and WebSocket communication.
- Public API surfaces `Sendable` value types only and provides an `AsyncStream<ClientEvent>` for UI consumers.
- Connection state transitions (`connecting → authenticated → subscribed → disconnected`) are explicit.
- REST helpers use `async/await` with typed snapshots (`EntityStateSnapshot`).
- Ping handling is timer-free; we schedule a structured `Task` that sleeps and issues Home Assistant `ping` frames.

## Usage Sketch

```swift
let configuration = HomeAssistantConfiguration(
    host: "ha.local",
    token: Secrets.haToken
)
let client = HomeAssistantClient(configuration: configuration)

let events = client.events()
Task {
    for await event in events {
        switch event {
        case .connectionState(let state):
            print("state ->", state)
        case .stateChanged(let payload):
            print("entity", payload.entityID, "=", payload.state)
        case .ping(let id):
            print("ping round-trip", id)
        }
    }
}

try await client.connect()
let sensor = try await client.fetchEntityState("sensor.outside_temperature")
```

## Integration Notes

- The main app uses `HomeAssistantService` to wrap this actor and expose an `ObservableObject` API to SwiftUI.
- Widgets continue to read data from `SharedSensorStorage`; only the main app speaks to Home Assistant directly.
- With concurrency boundaries centralised here, consider enabling `SWIFT_STRICT_CONCURRENCY = complete` and `SWIFT_VERSION = 6` across the project so the compiler can surface any remaining race conditions.
