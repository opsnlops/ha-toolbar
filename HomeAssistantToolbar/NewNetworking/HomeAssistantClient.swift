import Foundation
import OSLog

// MARK: - Configuration

public struct HomeAssistantConfiguration: Sendable, Hashable {
    public let host: String
    public let port: Int
    public let useTLS: Bool
    public let token: String
    public let webSocketPath: String
    public let restStatesPath: String

    public init(
        host: String,
        port: Int = 443,
        useTLS: Bool = true,
        token: String,
        webSocketPath: String = "/api/websocket",
        restStatesPath: String = "/api/states"
    ) {
        self.host = host
        self.port = port
        self.useTLS = useTLS
        self.token = token
        self.webSocketPath = webSocketPath
        self.restStatesPath = restStatesPath
    }

    public func makeWebSocketURL() throws -> URL {
        try makeURL(path: webSocketPath, secure: useTLS, schemeOverride: useTLS ? "wss" : "ws")
    }

    public func makeRESTStatesURL(entityID: String? = nil) throws -> URL {
        var url = try makeURL(path: restStatesPath, secure: useTLS)
        if let entityID {
            url.appendPathComponent(entityID)
        }
        return url
    }

    private func makeURL(path: String, secure: Bool, schemeOverride: String? = nil) throws -> URL {
        var components = URLComponents()
        components.scheme = schemeOverride ?? (secure ? "https" : "http")
        components.host = host
        components.port = port
        components.path = path.hasPrefix("/") ? path : "/" + path

        guard let url = components.url else {
            throw HomeAssistantClientError.invalidConfiguration("Unable to build URL for \(components.path)")
        }
        return url
    }
}

// MARK: - Public Models

public enum ConnectionState: Sendable, Equatable {
    case disconnected(DisconnectionReason?)
    case connecting
    case authenticated
    case subscribed
}

public enum DisconnectionReason: Sendable, Equatable {
    case userInitiated
    case networkFailure(String)
    case authenticationFailed(String)
}

public enum HomeAssistantClientError: Error, Sendable, Equatable {
    case invalidConfiguration(String)
    case handshakeFailed(String)
    case networkFailure(String)
    case httpFailure(Int)
    case decodingFailure(String)
}

public struct EntityStateSnapshot: Sendable, Decodable, Equatable {
    public let entityID: String
    public let state: String
    public let lastChanged: Date?
    public let lastUpdated: Date?

    enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case state
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
    }
}

public struct StateChangedEvent: Sendable, Equatable {
    public let entityID: String
    public let state: String
    public let rawPayload: Data
}

public enum ClientEvent: Sendable, Equatable {
    case connectionState(ConnectionState)
    case stateChanged(StateChangedEvent)
    case ping(roundTripID: Int)
}

// MARK: - HomeAssistantClient

public actor HomeAssistantClient {
    private enum HandshakePhase: Sendable {
        case awaitingAuthRequired
        case awaitingAuthOK
        case awaitingSubscriptionAck(id: Int)
        case ready
    }

    private let configuration: HomeAssistantConfiguration
    private let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "HomeAssistantClient")

    private let restSession: URLSession
    private let webSocketSession: URLSession

    private var connectionState: ConnectionState = .disconnected(nil) {
        didSet { publish(.connectionState(connectionState)) }
    }

    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?

    private let eventStream: AsyncStream<ClientEvent>
    private var eventContinuation: AsyncStream<ClientEvent>.Continuation

    private var nextMessageIdentifier: Int = 1
    private var handshakePhase: HandshakePhase = .awaitingAuthRequired

    // MARK: Lifecycle

    public init(
        configuration: HomeAssistantConfiguration,
        restSessionConfiguration: URLSessionConfiguration = .default,
        webSocketSessionConfiguration: URLSessionConfiguration = .default
    ) {
        self.configuration = configuration

        var restConfiguration = restSessionConfiguration
        restConfiguration.waitsForConnectivity = true
        restConfiguration.timeoutIntervalForRequest = 30
        restConfiguration.timeoutIntervalForResource = 60

        let restSession = URLSession(configuration: restConfiguration)
        let webSocketSession = URLSession(configuration: webSocketSessionConfiguration)
        self.restSession = restSession
        self.webSocketSession = webSocketSession

        var continuation: AsyncStream<ClientEvent>.Continuation!
        self.eventStream = AsyncStream { continuation = $0 }
        continuation.onTermination = { [weak restSession, weak webSocketSession] _ in
            restSession?.invalidateAndCancel()
            webSocketSession?.invalidateAndCancel()
        }
        self.eventContinuation = continuation
    }

    deinit {
        eventContinuation.finish()
    }

    // MARK: Public API

    public func events() -> AsyncStream<ClientEvent> {
        eventStream
    }

    public func currentState() -> ConnectionState {
        connectionState
    }

    @discardableResult
    public func connect() async throws -> ConnectionState {
        if case .connecting = connectionState {
            logger.debug("Connect requested while already connecting")
            return connectionState
        }
        if case .subscribed = connectionState {
            logger.debug("Connect requested while already subscribed")
            return connectionState
        }

        connectionState = .connecting
        handshakePhase = .awaitingAuthRequired

        let url = try configuration.makeWebSocketURL()
        logger.info("Opening Home Assistant websocket at \(url.absoluteString, privacy: .public)")

        let task = webSocketSession.webSocketTask(with: url)
        webSocketTask = task
        task.resume()

        startReceiveLoop()
        return connectionState
    }

    public func disconnect(reason: DisconnectionReason = .userInitiated) {
        stopPingLoop()
        receiveTask?.cancel()
        receiveTask = nil

        if let task = webSocketTask {
            task.cancel(with: .goingAway, reason: nil)
        }
        webSocketTask = nil

        connectionState = .disconnected(reason)
    }

    public func fetchEntityState(_ entityID: String) async throws -> EntityStateSnapshot {
        var request = URLRequest(url: try configuration.makeRESTStatesURL(entityID: entityID))
        request.httpMethod = "GET"
        request.addValue("Bearer \(configuration.token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let (data, response) = try await restSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HomeAssistantClientError.networkFailure("Missing HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            throw HomeAssistantClientError.httpFailure(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(EntityStateSnapshot.self, from: data)
        } catch {
            throw HomeAssistantClientError.decodingFailure("Failed to decode entity state: \(error.localizedDescription)")
        }
    }

    // MARK: Private Helpers

    private func startReceiveLoop() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            await self?.runReceiveLoop()
        }
    }

    private func runReceiveLoop() async {
        guard let webSocketTask else { return }
        logger.debug("Starting websocket receive loop")

        do {
            while !Task.isCancelled {
                let message = try await webSocketTask.receive()
                try await handle(message: message)
            }
        } catch is CancellationError {
            logger.debug("Receive loop cancelled")
        } catch {
            logger.error("Receive loop failed: \(error.localizedDescription, privacy: .public)")
            await handleFailure(.networkFailure(error.localizedDescription))
        }
    }

    private func handle(message: URLSessionWebSocketTask.Message) async throws {
        switch message {
        case .string(let text):
            try await handle(text: text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                try await handle(text: text)
            } else {
                logger.warning("Ignoring binary websocket frame of size \(data.count)")
            }
        @unknown default:
            logger.warning("Ignoring unknown websocket frame")
        }
    }

    private func handle(text: String) async throws {
        guard let data = text.data(using: .utf8) else {
            logger.error("Unable to convert websocket text to data")
            return
        }

        let envelope: WebSocketEnvelope
        do {
            envelope = try JSONDecoder().decode(WebSocketEnvelope.self, from: data)
        } catch {
            logger.error("Failed to decode websocket message: \(error.localizedDescription)")
            return
        }

        switch envelope.type {
        case "auth_required":
            try await sendAuthentication()
            handshakePhase = .awaitingAuthOK
        case "auth_ok":
            connectionState = .authenticated
            try await subscribeToStateChanges()
        case "auth_invalid":
            let message = envelope.message ?? "Authentication failed"
            connectionState = .disconnected(.authenticationFailed(message))
            throw HomeAssistantClientError.handshakeFailed(message)
        case "result":
            if case let .awaitingSubscriptionAck(expectedID) = handshakePhase,
               let id = envelope.id,
               id == expectedID,
               envelope.success == true {
                handshakePhase = .ready
                connectionState = .subscribed
                startPingLoop()
            }
        case "event":
            if let event = envelope.event?.data?.newState {
                publish(.stateChanged(StateChangedEvent(entityID: event.entityID, state: event.state, rawPayload: data)))
            }
        case "pong":
            if let id = envelope.id {
                publish(.ping(roundTripID: id))
            }
        default:
            logger.debug("Unhandled websocket message type: \(envelope.type, privacy: .public)")
        }
    }

    private func sendAuthentication() async throws {
        guard let webSocketTask else { return }
        let payload: [String: Any] = [
            "type": "auth",
            "access_token": configuration.token
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw HomeAssistantClientError.handshakeFailed("Unable to encode auth payload")
        }
        try await webSocketTask.send(.string(text))
        logger.debug("Sent authentication payload")
    }

    private func subscribeToStateChanges() async throws {
        guard let webSocketTask else { return }
        let identifier = nextIdentifier()
        handshakePhase = .awaitingSubscriptionAck(id: identifier)

        let payload: [String: Any] = [
            "id": identifier,
            "type": "subscribe_events",
            "event_type": "state_changed"
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw HomeAssistantClientError.handshakeFailed("Unable to encode subscription payload")
        }
        try await webSocketTask.send(.string(text))
        logger.info("Requested state_changed subscription")
    }

    private func startPingLoop() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            guard let self else { return }
            var identifier = await self.nextIdentifier()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                identifier = await self.sendPing(identifier: identifier)
            }
        }
    }

    private func stopPingLoop() {
        pingTask?.cancel()
        pingTask = nil
    }

    private func sendPing(identifier: Int) async -> Int {
        guard let webSocketTask else { return identifier }
        let payload: [String: Any] = ["type": "ping", "id": identifier]
        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            if let text = String(data: data, encoding: .utf8) {
                try await webSocketTask.send(.string(text))
                logger.debug("Sent ping id=\(identifier)")
                return identifier + 1
            }
        } catch {
            logger.error("Failed to send ping: \(error.localizedDescription)")
            await handleFailure(.networkFailure(error.localizedDescription))
        }
        return identifier
    }

    private func handleFailure(_ reason: DisconnectionReason) async {
        stopPingLoop()
        receiveTask?.cancel()
        receiveTask = nil

        if let task = webSocketTask {
            task.cancel(with: .goingAway, reason: nil)
        }
        webSocketTask = nil

        connectionState = .disconnected(reason)
    }

    private func publish(_ event: ClientEvent) {
        eventContinuation.yield(event)
    }

    private func nextIdentifier() -> Int {
        defer { nextMessageIdentifier += 1 }
        return nextMessageIdentifier
    }
}

// MARK: - Websocket Envelope

private struct WebSocketEnvelope: Decodable, Sendable {
    let id: Int?
    let type: String
    let success: Bool?
    let message: String?
    let event: WebSocketEventPayload?

    struct WebSocketEventPayload: Decodable, Sendable {
        let data: EventData?
    }

    struct EventData: Decodable, Sendable {
        let newState: EntityState

        enum CodingKeys: String, CodingKey {
            case newState = "new_state"
        }
    }

    struct EntityState: Decodable, Sendable {
        let entityID: String
        let state: String

        enum CodingKeys: String, CodingKey {
            case entityID = "entity_id"
            case state
        }
    }
}
