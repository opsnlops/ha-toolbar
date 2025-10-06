import Foundation
import Network
import OSLog
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct EntityState: Decodable {
    let state: String
}


class WebSocketClient : ObservableObject {

    static let shared = WebSocketClient()

    private var webSocketTask: URLSessionWebSocketTask?

    let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "WebSocketClient")

    @AppStorage("serverPort") private var serverPort: Int = 443
    @AppStorage("serverUseTLS") private var serverUseTLS: Bool = true

    @AppStorage("outsideTemperatureEntity") private var outsideTemperatureEntity: String = ""
    @AppStorage("windSpeedEntity") private var windSpeedEntity: String = ""
    @AppStorage("rainAmountEntity") private var rainAmountEntity: String = ""
    @AppStorage("temperatureMaxEntity") private var temperatureMaxEntity: String = ""
    @AppStorage("temperatureMinEntity") private var temperatureMinEntity: String = ""
    @AppStorage("humidityEntity") private var humidityEntity: String = ""
    @AppStorage("windSpeedMaxEntity") private var windSpeedMaxEntity: String = ""
    @AppStorage("pm25Entity") private var pm25Entity: String = ""
    @AppStorage("lightLevelEntity") private var lightLevelEntity: String = ""
    @AppStorage("aqiEntity") private var aqiEntity: String = ""
    @AppStorage("windDirectionEntity") private var windDirectionEntity: String = ""

    private var serverHostname: String?
    private var authToken: String?

    let sensorData = MonitoredSensors.shared

    private var pingTimer: Timer?
    private var isWaitingForPong = false
    private var pingId: Int = Int.random(in: 100...10000)

    @Published var isConnected: Bool = false
    @Published var totalPings: Int = 0

    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    private var isNetworkAvailable = true

    #if os(macOS)
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    #elseif os(iOS)
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?
    #endif

    init() {
        setupNetworkMonitoring()
        #if os(macOS)
        setupSleepWakeNotifications()
        #elseif os(iOS)
        setupBackgroundForegroundNotifications()
        #endif
    }

    deinit {
        networkMonitor.cancel()
        #if os(macOS)
        if let sleepObserver = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
        }
        if let wakeObserver = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        #elseif os(iOS)
        if let backgroundObserver = backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
        if let foregroundObserver = foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
        }
        #endif
    }

    func makeWebsocketURL() -> URL {
        var components = URLComponents()
        components.host = serverHostname
        components.port = serverPort
        components.scheme = serverUseTLS ? "wss" : "ws"
        components.path.append("/api/websocket")
        return components.url!
    }

    func makeReadStateURL() -> URL {
        var components = URLComponents()
        components.host = serverHostname
        components.port = serverPort
        components.scheme = serverUseTLS ? "https" : "http"
        components.path.append("/api/states/")
        return components.url!
    }


    func configure(hostname: String, authToken: String) {
        self.serverHostname = hostname
        self.authToken = authToken
    }

    func connect() -> Result<String, ServerError> {

        guard serverHostname != nil && authToken != nil else {
            logger.error("Invalid configuration: hostname: \(self.serverHostname ?? "") and authToken: \(self.authToken ?? "")")
            return .failure(.invalidConfiguration)
        }

        if let serverHostname {
            logger.info("Using hostname: \(serverHostname)")
            let url = makeWebsocketURL()
            webSocketTask = URLSession.shared.webSocketTask(with: url)
            webSocketTask?.resume()

            DispatchQueue.main.async {
                self.isConnected = true
            }

            // Start receiving messages
            Task {
                await authenticate()
                startPingTimer()
                await listenForMessages()
            }

            return .success("Connected to \(serverHostname)")
        }
        else {
            return .failure(.invalidConfiguration)
        }


    }

    func disconnect() {

        DispatchQueue.main.async {
            self.isConnected = false
        }

        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }


    func readSensorState(_ entity: String) async -> Result<String, ServerError> {

        let baseUrl = makeReadStateURL()
        let url = baseUrl.appendingPathComponent(entity)

        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        request.addValue("Bearer \(authToken ?? "uh-oh")", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let entityData = try JSONDecoder().decode(EntityState.self, from: data)

            logger.debug("Read sensor state: \(entityData.state)")
            return .success(entityData.state)
        }
        catch {
            logger.warning("Failed to read sensor state: \(error)")
            return .failure(.networkError(error.localizedDescription))
        }

    }

    func sendMessage(_ message: String) async {
        guard let webSocketTask = webSocketTask else {
            logger.error("WebSocket not connected.")
            return
        }

        do {
            try await webSocketTask.send(.string(message))
            logger.debug("Sent message: \(message)")
        } catch {
            logger.warning("Failed to send message: \(error)")
        }
    }

    private func authenticate() async {
        guard let webSocketTask = webSocketTask else { return }
        guard let token = authToken else {
            logger.error("No auth token provided; cannot authenticate.")
            return
        }

        // Wait for the initial auth_required message
        let initialMessage = try? await webSocketTask.receive()
        logger.debug("Initial Message: \(String(describing: initialMessage))")

        // Prepare authentication message
        let authMessage = [
            "type": "auth",
            "access_token": token
        ]

        do {
            // Convert to JSON string
            let authData = try JSONSerialization.data(withJSONObject: authMessage)
            if let authString = String(data: authData, encoding: .utf8) {

                logger.debug("Auth message being sent: \(authString, privacy: .private)")
                // Send the message as a .string type
                try await webSocketTask.send(.string(authString))
                logger.debug("Sent authentication message")
            }
        } catch {
            logger.error("Failed to create or send auth message: \(error.localizedDescription)")
        }
    }


    private func listenForMessages() async {
        guard let webSocketTask = webSocketTask else { return }

        do {
            while true {
                let message = try await webSocketTask.receive()
                switch message {
                    case .string(let text):
                        //logger.trace("Received raw text message: \(text, privacy: .private)")

                        // Parse and handle the JSON message
                        handleIncomingMessage(text)

                    case .data(_):
                        logger.warning("Unexpected binary data received. Ignoring.")

                    @unknown default:
                        logger.warning("Unknown message type received.")
                }
            }
        } catch {
            logger.error("Error receiving message: \(error)")
            await reconnect()
        }
    }


    private func reconnect() async {
        stopPingTimer()
        try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
        logger.info("Attempting to reconnect...")
        _ = connect()
    }





    // Helper function to parse and route incoming JSON messages
    private func handleIncomingMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else {
            logger.error("Failed to convert text to data.")
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let messageType = json["type"] as? String {
                //logger.debug("Parsed message with type: \(messageType, privacy: .public)")
                routeMessage(json, type: messageType)
            } else {
                logger.error("Invalid JSON structure in message.")
            }
        } catch {
            logger.error("Failed to parse JSON message: \(error.localizedDescription)")
        }
    }

    private func routeMessage(_ json: [String: Any], type: String) {
        switch type {
            case "auth_ok":
                logger.info("Authenticated successfully with Home Assistant.")
                // Now that we're authenticated, subscribe to the sensor
                Task {
                    await readIntialState()
                    await subscribeToSensorState()
                }

            case "auth_invalid":
                logger.error("Authentication failed: Invalid auth token.")
                disconnect()

            case "event":
                handleEvent(json)

            case "result":
                handleResult(json)

            case "pong":
                handlePong(json)

            default:
                logger.warning("Unhandled message type: \(type)")
        }
    }


    private func subscribeToSensorState() async {
        guard let webSocketTask = webSocketTask else { return }

        let subscriptionMessage: [String: Any] = [
            "id": 1,
            "type": "subscribe_events",
            "event_type": "state_changed"
        ]

        do {
            let subscriptionData = try JSONSerialization.data(withJSONObject: subscriptionMessage)
            if let subscriptionString = String(data: subscriptionData, encoding: .utf8) {
                logger.debug("Subscription message being sent: \(subscriptionString)")
                try await webSocketTask.send(.string(subscriptionString))
                logger.info("Subscribed to state changes")
            }
        } catch {
            logger.error("Failed to send subscription message: \(error.localizedDescription)")
        }
    }

    func loadSensorData() async {
        await readIntialState()
    }

    private func readIntialState() async {

        // Now that we know we're authed, use the REST API to get the current state
        // of the sensors

        let temperatureResponse = await readSensorState(outsideTemperatureEntity)
        switch (temperatureResponse) {
            case .success(let temperature):
                DispatchQueue.main.async {
                    self.sensorData.updateOutsideTemperature(Double(temperature)!)
                }
            case .failure(let error):
                logger.error("Failed to read temperature initial state: \(error.localizedDescription)")
        }

        let rainAmountResponse = await readSensorState(rainAmountEntity)
        switch (rainAmountResponse) {
            case .success(let rainAmount):
                DispatchQueue.main.async {
                    self.sensorData.updateRainAmount(Double(rainAmount)!)
                }
            case .failure(let error):
                logger.error("Failed to read rain initial state: \(error.localizedDescription)")
        }

        let windSpeedResponse = await readSensorState(windSpeedEntity)
        switch (windSpeedResponse) {
            case .success(let windSpeed):
                DispatchQueue.main.async {
                    self.sensorData.updateWindSpeed(Double(windSpeed)!)
                }
            case .failure(let error):
                logger.error("Failed to read wind speed initial state: \(error.localizedDescription)")
        }

        // Read new sensors
        if !temperatureMaxEntity.isEmpty {
            let response = await readSensorState(temperatureMaxEntity)
            if case .success(let value) = response, let doubleValue = Double(value) {
                DispatchQueue.main.async { self.sensorData.updateTemperatureMax(doubleValue) }
            }
        }

        if !temperatureMinEntity.isEmpty {
            let response = await readSensorState(temperatureMinEntity)
            if case .success(let value) = response, let doubleValue = Double(value) {
                DispatchQueue.main.async { self.sensorData.updateTemperatureMin(doubleValue) }
            }
        }

        if !humidityEntity.isEmpty {
            let response = await readSensorState(humidityEntity)
            if case .success(let value) = response, let doubleValue = Double(value) {
                DispatchQueue.main.async { self.sensorData.updateHumidity(doubleValue) }
            }
        }

        if !windSpeedMaxEntity.isEmpty {
            let response = await readSensorState(windSpeedMaxEntity)
            if case .success(let value) = response, let doubleValue = Double(value) {
                DispatchQueue.main.async { self.sensorData.updateWindSpeedMax(doubleValue) }
            }
        }

        if !pm25Entity.isEmpty {
            let response = await readSensorState(pm25Entity)
            if case .success(let value) = response, let doubleValue = Double(value) {
                DispatchQueue.main.async { self.sensorData.updatePM25(doubleValue) }
            }
        }

        if !lightLevelEntity.isEmpty {
            let response = await readSensorState(lightLevelEntity)
            if case .success(let value) = response, let doubleValue = Double(value) {
                DispatchQueue.main.async { self.sensorData.updateLightLevel(doubleValue) }
            }
        }

        if !aqiEntity.isEmpty {
            let response = await readSensorState(aqiEntity)
            if case .success(let value) = response, let doubleValue = Double(value) {
                DispatchQueue.main.async { self.sensorData.updateAQI(doubleValue) }
            }
        }

        if !windDirectionEntity.isEmpty {
            let response = await readSensorState(windDirectionEntity)
            if case .success(let value) = response {
                DispatchQueue.main.async { self.sensorData.updateWindDirection(value) }
            }
        }

    }



    private func handleEvent(_ json: [String: Any]) {
        // Increment total events on the main queue
        DispatchQueue.main.async {
            self.sensorData.incrementTotalEventsProcessed()
        }

        guard
            let event = json["event"] as? [String: Any],
            let data = event["data"] as? [String: Any],
            let newState = data["new_state"] as? [String: Any],
            let entityId = newState["entity_id"] as? String
        else {
            logger.error("Invalid event structure.")
            return
        }

        // Switch on entityId to handle specific sensors
        switch entityId {
            case outsideTemperatureEntity:
                if let temperatureString = newState["state"] as? String,
                   let temperature = Double(temperatureString) {
                    DispatchQueue.main.async {
                        self.sensorData.updateOutsideTemperature(temperature)
                        self.logger.info("Outside temperature updated: \(temperatureString)")
                    }
                }

            case windSpeedEntity:
                if let windSpeedString = newState["state"] as? String,
                   let windSpeed = Double(windSpeedString) {
                    DispatchQueue.main.async {
                        self.sensorData.updateWindSpeed(windSpeed)
                        self.logger.info("Wind speed updated: \(windSpeedString)")
                    }
                }

            case rainAmountEntity:
                if let rainAmountString = newState["state"] as? String,
                   let rainAmount = Double(rainAmountString) {
                    DispatchQueue.main.async {
                        self.sensorData.updateRainAmount(rainAmount)
                        self.logger.info("Rain amount updated: \(rainAmountString)")
                    }
                }

            case temperatureMaxEntity:
                if let valueString = newState["state"] as? String,
                   let value = Double(valueString) {
                    DispatchQueue.main.async {
                        self.sensorData.updateTemperatureMax(value)
                        self.logger.info("Temperature max updated: \(valueString)")
                    }
                }

            case temperatureMinEntity:
                if let valueString = newState["state"] as? String,
                   let value = Double(valueString) {
                    DispatchQueue.main.async {
                        self.sensorData.updateTemperatureMin(value)
                        self.logger.info("Temperature min updated: \(valueString)")
                    }
                }

            case humidityEntity:
                if let valueString = newState["state"] as? String,
                   let value = Double(valueString) {
                    DispatchQueue.main.async {
                        self.sensorData.updateHumidity(value)
                        self.logger.info("Humidity updated: \(valueString)")
                    }
                }

            case windSpeedMaxEntity:
                if let valueString = newState["state"] as? String,
                   let value = Double(valueString) {
                    DispatchQueue.main.async {
                        self.sensorData.updateWindSpeedMax(value)
                        self.logger.info("Wind speed max updated: \(valueString)")
                    }
                }

            case pm25Entity:
                if let valueString = newState["state"] as? String,
                   let value = Double(valueString) {
                    DispatchQueue.main.async {
                        self.sensorData.updatePM25(value)
                        self.logger.info("PM2.5 updated: \(valueString)")
                    }
                }

            case lightLevelEntity:
                if let valueString = newState["state"] as? String,
                   let value = Double(valueString) {
                    DispatchQueue.main.async {
                        self.sensorData.updateLightLevel(value)
                        self.logger.info("Light level updated: \(valueString)")
                    }
                }

            case aqiEntity:
                if let valueString = newState["state"] as? String,
                   let value = Double(valueString) {
                    DispatchQueue.main.async {
                        self.sensorData.updateAQI(value)
                        self.logger.info("AQI updated: \(valueString)")
                    }
                }

            case windDirectionEntity:
                if let valueString = newState["state"] as? String {
                    DispatchQueue.main.async {
                        self.sensorData.updateWindDirection(valueString)
                        self.logger.info("Wind direction updated: \(valueString)")
                    }
                }

            default:
                return
                //logger.trace("Unhandled entity: \(entityId)")
        }
    }

    private func handlePong(_ json: [String: Any]) {
        logger.debug("Handling pong: \(json, privacy: .private)")
        isWaitingForPong = false
        pingId += 1

        DispatchQueue.main.async {
            self.totalPings += 1
        }

    }

    private func handleResult(_ json: [String: Any]) {
        // Process result messages from Home Assistant
        logger.debug("Handling result: \(json, privacy: .private)")
    }


    private func sendPing() async {

        // If we're still waiting for a pong, reconnect
        guard !isWaitingForPong else {
            logger.error("Ping timeout, marking WebSocket as disconnected")
            await reconnect()
            return
        }

        guard let webSocketTask = webSocketTask else { return }

        // Prepare the ping
        let pingMessage = [
            "type": "ping",
            "id": pingId
        ] as [String : Any]

        do {
            // Convert to JSON string
            let pingData = try JSONSerialization.data(withJSONObject: pingMessage)
            if let pingString = String(data: pingData, encoding: .utf8) {

                isWaitingForPong = true

                logger.debug("Ping message being sent: \(pingString, privacy: .private)")
                try await webSocketTask.send(.string(pingString))
                logger.debug("Sent ping")
            }
        } catch {
            logger.error("Failed to send ping: \(error.localizedDescription)")
            await reconnect()

        }
    }


    private func startPingTimer() {

        // Stop the timer if it's running
        stopPingTimer()

        logger.debug("Starting ping timer")

        DispatchQueue.main.async {
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                Task {
                    self.logger.debug("Ping timer fired")
                    await self.sendPing()
                }
            }
            RunLoop.main.add(self.pingTimer!, forMode: .common)
            self.logger.debug("Ping timer setup complete")
        }

    }

    private func stopPingTimer() {

        logger.debug("stopping any ping timers")

        self.isWaitingForPong = false
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func reconnect() {

        // Stop the timer
        stopPingTimer()

        // Handle the socket
        webSocketTask?.cancel(with: .goingAway, reason: nil)

        // .. and reconnect
        _ = connect()
    }

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let wasAvailable = self.isNetworkAvailable
            self.isNetworkAvailable = path.status == .satisfied

            if self.isNetworkAvailable && !wasAvailable {
                // Network came back online
                self.logger.info("Network became available, reconnecting websocket")
                Task {
                    try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                    _ = self.connect()
                }
            } else if !self.isNetworkAvailable && wasAvailable {
                // Network went offline
                self.logger.info("Network became unavailable, disconnecting websocket")
                self.stopPingTimer()
                self.webSocketTask?.cancel(with: .goingAway, reason: nil)
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
        logger.debug("Network monitoring configured")
    }

    #if os(macOS)
    private func setupSleepWakeNotifications() {
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("System going to sleep, disconnecting websocket")
            self.stopPingTimer()
            self.webSocketTask?.cancel(with: .goingAway, reason: nil)
            DispatchQueue.main.async {
                self.isConnected = false
            }
        }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("System woke from sleep, reconnecting websocket")
            // Give the network a moment to come back up
            Task {
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                _ = self.connect()
            }
        }

        logger.debug("Sleep/wake notifications configured")
    }
    #elseif os(iOS)
    private func setupBackgroundForegroundNotifications() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("App entering background, disconnecting websocket")
            self.stopPingTimer()
            self.webSocketTask?.cancel(with: .goingAway, reason: nil)
            DispatchQueue.main.async {
                self.isConnected = false
            }
        }

        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("App entering foreground, reconnecting websocket")
            // Give the network a moment to come back up
            Task {
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                _ = self.connect()
            }
        }

        logger.debug("Background/foreground notifications configured")
    }
    #endif
}

