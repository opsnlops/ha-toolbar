import Foundation
import OSLog
import SwiftUI

class WebSocketClient {
    private var webSocketTask: URLSessionWebSocketTask?

    let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "WebSocketClient")

    @AppStorage("serverPort") private var serverPort: Int = 443
    @AppStorage("serverUseTLS") private var serverUseTLS: Bool = true

    @AppStorage("outsideTemperatureEntity") private var outsideTemperatureEntity: String = ""
    @AppStorage("windSpeedEntity") private var windSpeedEntity: String = ""
    @AppStorage("rainAmountEntity") private var rainAmountEntity: String = ""

    private var serverHostname: String = ""
    private var authToken: String?

    let sensorData = MonitoredSensors.shared

    init(hostname: String, authToken: String?) {
        self.serverHostname = hostname
        self.authToken = authToken
    }

    func makeURL() -> URL {
        var components = URLComponents()
        components.host = serverHostname
        components.port = serverPort
        components.scheme = serverUseTLS ? "wss" : "ws"
        components.path.append("/api/websocket")
        return components.url!
    }

    func connect() {
        logger.info("Connecting to \(self.serverHostname)")
        let url = makeURL()
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()

        // Start receiving messages
        Task {
            await authenticate()
            await listenForMessages()
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
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
        try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
        logger.info("Attempting to reconnect...")
        connect()
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
                    await subscribeToSensorState()
                }

            case "auth_invalid":
                logger.error("Authentication failed: Invalid auth token.")
                disconnect()

            case "event":
                handleEvent(json)

            case "result":
                handleResult(json)

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

            default:
                return
                //logger.trace("Unhandled entity: \(entityId)")
        }
    }


    private func handleResult(_ json: [String: Any]) {
        // Process result messages from Home Assistant
        logger.debug("Handling result: \(json, privacy: .private)")
    }
}

