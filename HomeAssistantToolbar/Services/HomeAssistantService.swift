#if APP_MAIN_TARGET
import Foundation
import OSLog
import SwiftUI
import Combine

/// Main-actor façade around `HomeAssistantClient` that bridges actor events into
/// observable state for the UI and coordinates reconnection behaviour.
@MainActor
final class HomeAssistantService: ObservableObject {
    static let shared = HomeAssistantService()

    private let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "HomeAssistantService")
    private let sensors = MonitoredSensors.shared

    private var configuration: HomeAssistantConfiguration?
    private var client: HomeAssistantClient?
    private var eventsTask: Task<Void, Never>?
    private var hasLoadedInitialState = false
    private var reconnectTask: Task<Void, Never>?

    @Published var connectionState: ConnectionState = .disconnected(nil)
    @Published var isConnected: Bool = false
    @Published var totalPings: Int = 0

#if DEBUG
    private let verboseLoggingEnabled = true
#else
    private let verboseLoggingEnabled = false
#endif

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
    @AppStorage("pressureEntity") private var pressureEntity: String = ""

    private var serverHostname: String?
    private var authToken: String?

    private init() {}

    func configure(hostname: String, authToken: String) {
        serverHostname = hostname
        self.authToken = authToken

        guard !hostname.isEmpty, !authToken.isEmpty else {
            logger.warning("Configuration incomplete; skipping client creation")
            configuration = nil
            client = nil
            eventsTask?.cancel()
            eventsTask = nil
            return
        }

        let configuration = HomeAssistantConfiguration(
            host: hostname,
            port: serverPort,
            useTLS: serverUseTLS,
            token: authToken
        )

        self.configuration = configuration
        self.client = HomeAssistantClient(configuration: configuration)
        eventsTask?.cancel()
        eventsTask = nil
        totalPings = 0
        hasLoadedInitialState = false
    }

    @discardableResult
    func connect() -> Result<String, ServerError> {
        guard let configuration else {
            logger.error("connect called before configuration was set")
            return .failure(.invalidConfiguration)
        }

        guard let client else {
            logger.fault("Client missing even though configuration exists")
            return .failure(.invalidConfiguration)
        }

        startEventStreamIfNeeded(for: client)

        Task { [weak self] in
            do {
                let state = try await client.connect()
                await MainActor.run {
                    self?.handleConnectionState(state)
                }
            } catch {
                await MainActor.run {
                    self?.handleFailure(.networkFailure(error.localizedDescription))
                }
            }
        }

        return .success("Connecting to \(configuration.host)")
    }

    func disconnect() {
        eventsTask?.cancel()
        eventsTask = nil

        handleFailure(.userInitiated)

        guard let client else { return }
        Task {
            await client.disconnect(reason: .userInitiated)
        }
    }

    func loadSensorData() async {
        await loadInitialState()
    }

    private func startEventStreamIfNeeded(for client: HomeAssistantClient) {
        guard eventsTask == nil else { return }

        eventsTask = Task { [weak self] in
            let stream = await client.events()
            for await event in stream {
                await MainActor.run {
                    self?.handle(event)
                }
            }
        }
    }

    private func handle(_ event: ClientEvent) {
        switch event {
        case .connectionState(let state):
            handleConnectionState(state)
        case .stateChanged(let payload):
            sensors.incrementTotalEventsProcessed()
            handleStateChanged(payload)
        case .ping:
            totalPings += 1
        }
    }

    private func handleConnectionState(_ state: ConnectionState) {
        reconnectTask?.cancel()
        connectionState = state
        switch state {
        case .connecting:
            isConnected = false
            hasLoadedInitialState = false
        case .authenticated:
            isConnected = true
        case .subscribed:
            isConnected = true
            if !hasLoadedInitialState {
                hasLoadedInitialState = true
                Task { await loadInitialState() }
            }
        case .disconnected(let reason):
            isConnected = false
            hasLoadedInitialState = false
            if let reason, case .networkFailure = reason {
                scheduleReconnect()
            }
        }
    }

    private func handleFailure(_ reason: DisconnectionReason) {
        connectionState = .disconnected(reason)
        isConnected = false
        hasLoadedInitialState = false
        if case .networkFailure = reason {
            scheduleReconnect()
        }
    }

    private func loadInitialState() async {
        guard client != nil else { return }

        await fetchAndApply(entityID: outsideTemperatureEntity) { [self] value in
            if let temperature = Double(value) {
                logVerbose("Initial state for \(self.outsideTemperatureEntity): \(temperature)")
                sensors.updateOutsideTemperature(temperature)
            }
        }

        await fetchAndApply(entityID: rainAmountEntity) { [self] value in
            if let rain = Double(value) {
                logVerbose("Initial state for \(self.rainAmountEntity): \(rain)")
                sensors.updateRainAmount(rain)
            }
        }

        await fetchAndApply(entityID: windSpeedEntity) { [self] value in
            if let wind = Double(value) {
                logVerbose("Initial state for \(self.windSpeedEntity): \(wind)")
                sensors.updateWindSpeed(wind)
            }
        }

        await fetchAndApply(entityID: temperatureMaxEntity) { [self] value in
            if let max = Double(value) {
                logVerbose("Initial state for \(self.temperatureMaxEntity): \(max)")
                sensors.updateTemperatureMax(max)
            }
        }

        await fetchAndApply(entityID: temperatureMinEntity) { [self] value in
            if let min = Double(value) {
                logVerbose("Initial state for \(self.temperatureMinEntity): \(min)")
                sensors.updateTemperatureMin(min)
            }
        }

        await fetchAndApply(entityID: humidityEntity) { [self] value in
            if let humidity = Double(value) {
                logVerbose("Initial state for \(self.humidityEntity): \(humidity)")
                sensors.updateHumidity(humidity)
            }
        }

        await fetchAndApply(entityID: windSpeedMaxEntity) { [self] value in
            if let windMax = Double(value) {
                logVerbose("Initial state for \(self.windSpeedMaxEntity): \(windMax)")
                sensors.updateWindSpeedMax(windMax)
            }
        }

        await fetchAndApply(entityID: pm25Entity) { [self] value in
            if let pm = Double(value) {
                logVerbose("Initial state for \(self.pm25Entity): \(pm)")
                sensors.updatePM25(pm)
            }
        }

        await fetchAndApply(entityID: lightLevelEntity) { [self] value in
            if let lux = Double(value) {
                logVerbose("Initial state for \(self.lightLevelEntity): \(lux)")
                sensors.updateLightLevel(lux)
            }
        }

        await fetchAndApply(entityID: aqiEntity) { [self] value in
            if let aqi = Double(value) {
                logVerbose("Initial state for \(self.aqiEntity): \(aqi)")
                sensors.updateAQI(aqi)
            }
        }

        await fetchAndApply(entityID: windDirectionEntity) { [self] value in
            logVerbose("Initial state for \(self.windDirectionEntity): \(value)")
            sensors.updateWindDirection(value)
        }

        await fetchAndApply(entityID: pressureEntity) { [self] value in
            if let pressure = Double(value) {
                logVerbose("Initial state for \(self.pressureEntity): \(pressure)")
                sensors.updatePressure(pressure)
            }
        }
    }

    private func fetchAndApply(entityID: String, _ apply: @escaping (String) -> Void) async {
        guard !entityID.isEmpty, let client else { return }

        do {
            let snapshot = try await client.fetchEntityState(entityID)
            apply(snapshot.state)
        } catch {
            logger.warning("Failed to fetch \(entityID): \(error.localizedDescription)")
        }
    }

    private func handleStateChanged(_ event: StateChangedEvent) {
        switch event.entityID {
        case outsideTemperatureEntity where !outsideTemperatureEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updateOutsideTemperature(value)
            }
        case windSpeedEntity where !windSpeedEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updateWindSpeed(value)
            }
        case rainAmountEntity where !rainAmountEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updateRainAmount(value)
            }
        case temperatureMaxEntity where !temperatureMaxEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updateTemperatureMax(value)
            }
        case temperatureMinEntity where !temperatureMinEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updateTemperatureMin(value)
            }
        case humidityEntity where !humidityEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updateHumidity(value)
            }
        case windSpeedMaxEntity where !windSpeedMaxEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updateWindSpeedMax(value)
            }
        case pm25Entity where !pm25Entity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updatePM25(value)
            }
        case lightLevelEntity where !lightLevelEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updateLightLevel(value)
            }
        case aqiEntity where !aqiEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updateAQI(value)
            }
        case windDirectionEntity where !windDirectionEntity.isEmpty:
            logVerbose("Streaming update \(event.entityID) -> \(event.state)")
            sensors.updateWindDirection(event.state)
        case pressureEntity where !pressureEntity.isEmpty:
            if let value = Double(event.state) {
                logVerbose("Streaming update \(event.entityID) -> \(value)")
                sensors.updatePressure(value)
            }
        default:
            break
        }
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            guard !self.isConnected else { return }
            _ = self.connect()
        }
    }

    private func logVerbose(_ message: String) {
        guard verboseLoggingEnabled else { return }
        logger.debug("\(message)")
    }
}
#endif
