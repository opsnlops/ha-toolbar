/// Shared App Group storage helpers
/// Exposes only static APIs so both the app and widgets can access data
/// without sharing mutable state.
import Foundation

/// Represents the trend direction of a sensor value
public enum Trend: String, Codable, Sendable {
    case up
    case down
    case stable

    /// Returns an SF Symbol name for the trend
    var symbolName: String {
        switch self {
        case .up:
            return "arrow.up"
        case .down:
            return "arrow.down"
        case .stable:
            return "arrow.forward"
        }
    }

    /// Returns a Unicode arrow character as fallback
    var unicodeArrow: String {
        switch self {
        case .up:
            return "↑"
        case .down:
            return "↓"
        case .stable:
            return "→"
        }
    }
}

/// Static namespace for reading/writing sensor data via the shared App Group.
enum SharedSensorStorage {

    private static let appGroupIdentifier = "group.io.opsnlops.HomeAssistantToolbar"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private enum Keys {
        static let outsideTemperature = "shared.outsideTemperature"
        static let windSpeed = "shared.windSpeed"
        static let rainAmount = "shared.rainAmount"
        static let temperatureMax = "shared.temperatureMax"
        static let temperatureMin = "shared.temperatureMin"
        static let humidity = "shared.humidity"
        static let windSpeedMax = "shared.windSpeedMax"
        static let pm25 = "shared.pm25"
        static let lightLevel = "shared.lightLevel"
        static let aqi = "shared.aqi"
        static let windDirection = "shared.windDirection"
        static let pressure = "shared.pressure"
        static let lastUpdated = "shared.lastUpdated"
        static let totalEventsProcessed = "shared.totalEventsProcessed"

        static let temperatureTrend = "shared.trend.temperature"
        static let windSpeedTrend = "shared.trend.windSpeed"
        static let humidityTrend = "shared.trend.humidity"
        static let pm25Trend = "shared.trend.pm25"
        static let lightLevelTrend = "shared.trend.lightLevel"
        static let pressureTrend = "shared.trend.pressure"

        static let serverHostname = "shared.serverHostname"
        static let serverPort = "shared.serverPort"
        static let serverUseTLS = "shared.serverUseTLS"
        static let authToken = "shared.authToken"
        static let temperatureEntity = "shared.temperatureEntity"
        static let windSpeedEntity = "shared.windSpeedEntity"
        static let rainAmountEntity = "shared.rainAmountEntity"
        static let temperatureMaxEntity = "shared.temperatureMaxEntity"
        static let temperatureMinEntity = "shared.temperatureMinEntity"
        static let humidityEntity = "shared.humidityEntity"
        static let windSpeedMaxEntity = "shared.windSpeedMaxEntity"
        static let pm25Entity = "shared.pm25Entity"
        static let lightLevelEntity = "shared.lightLevelEntity"
        static let aqiEntity = "shared.aqiEntity"
        static let windDirectionEntity = "shared.windDirectionEntity"
        static let pressureEntity = "shared.pressureEntity"
    }

    // MARK: - Write APIs

    static func saveOutsideTemperature(_ temperature: Double) { defaults?.set(temperature, forKey: Keys.outsideTemperature); updateLastUpdated() }
    static func saveWindSpeed(_ windSpeed: Double) { defaults?.set(windSpeed, forKey: Keys.windSpeed); updateLastUpdated() }
    static func saveRainAmount(_ rainAmount: Double) { defaults?.set(rainAmount, forKey: Keys.rainAmount); updateLastUpdated() }
    static func saveTemperatureMax(_ temperatureMax: Double) { defaults?.set(temperatureMax, forKey: Keys.temperatureMax); updateLastUpdated() }
    static func saveTemperatureMin(_ temperatureMin: Double) { defaults?.set(temperatureMin, forKey: Keys.temperatureMin); updateLastUpdated() }
    static func saveHumidity(_ humidity: Double) { defaults?.set(humidity, forKey: Keys.humidity); updateLastUpdated() }
    static func saveWindSpeedMax(_ windSpeedMax: Double) { defaults?.set(windSpeedMax, forKey: Keys.windSpeedMax); updateLastUpdated() }
    static func savePM25(_ pm25: Double) { defaults?.set(pm25, forKey: Keys.pm25); updateLastUpdated() }
    static func saveLightLevel(_ lightLevel: Double) { defaults?.set(lightLevel, forKey: Keys.lightLevel); updateLastUpdated() }
    static func saveAQI(_ aqi: Double) { defaults?.set(aqi, forKey: Keys.aqi); updateLastUpdated() }
    static func saveWindDirection(_ windDirection: String) { defaults?.set(windDirection, forKey: Keys.windDirection); updateLastUpdated() }
    static func savePressure(_ pressure: Double) { defaults?.set(pressure, forKey: Keys.pressure); updateLastUpdated() }

    static func saveTotalEventsProcessed(_ count: UInt64) { defaults?.set(count, forKey: Keys.totalEventsProcessed) }

    static func saveTemperatureTrend(_ trend: Trend) { defaults?.set(trend.rawValue, forKey: Keys.temperatureTrend) }
    static func saveWindSpeedTrend(_ trend: Trend) { defaults?.set(trend.rawValue, forKey: Keys.windSpeedTrend) }
    static func saveHumidityTrend(_ trend: Trend) { defaults?.set(trend.rawValue, forKey: Keys.humidityTrend) }
    static func savePM25Trend(_ trend: Trend) { defaults?.set(trend.rawValue, forKey: Keys.pm25Trend) }
    static func saveLightLevelTrend(_ trend: Trend) { defaults?.set(trend.rawValue, forKey: Keys.lightLevelTrend) }
    static func savePressureTrend(_ trend: Trend) { defaults?.set(trend.rawValue, forKey: Keys.pressureTrend) }

    static func saveConfiguration(hostname: String, port: Int, useTLS: Bool, authToken: String,
                                  temperatureEntity: String, windSpeedEntity: String, rainAmountEntity: String,
                                  temperatureMaxEntity: String, temperatureMinEntity: String, humidityEntity: String,
                                  windSpeedMaxEntity: String, pm25Entity: String, lightLevelEntity: String,
                                  aqiEntity: String, windDirectionEntity: String, pressureEntity: String) {
        defaults?.set(hostname, forKey: Keys.serverHostname)
        defaults?.set(port, forKey: Keys.serverPort)
        defaults?.set(useTLS, forKey: Keys.serverUseTLS)
        defaults?.set(authToken, forKey: Keys.authToken)
        defaults?.set(temperatureEntity, forKey: Keys.temperatureEntity)
        defaults?.set(windSpeedEntity, forKey: Keys.windSpeedEntity)
        defaults?.set(rainAmountEntity, forKey: Keys.rainAmountEntity)
        defaults?.set(temperatureMaxEntity, forKey: Keys.temperatureMaxEntity)
        defaults?.set(temperatureMinEntity, forKey: Keys.temperatureMinEntity)
        defaults?.set(humidityEntity, forKey: Keys.humidityEntity)
        defaults?.set(windSpeedMaxEntity, forKey: Keys.windSpeedMaxEntity)
        defaults?.set(pm25Entity, forKey: Keys.pm25Entity)
        defaults?.set(lightLevelEntity, forKey: Keys.lightLevelEntity)
        defaults?.set(aqiEntity, forKey: Keys.aqiEntity)
        defaults?.set(windDirectionEntity, forKey: Keys.windDirectionEntity)
        defaults?.set(pressureEntity, forKey: Keys.pressureEntity)
    }

    // MARK: - Read helpers

    static func getOutsideTemperature() -> Double { defaults?.double(forKey: Keys.outsideTemperature) ?? 0.0 }
    static func getWindSpeed() -> Double { defaults?.double(forKey: Keys.windSpeed) ?? 0.0 }
    static func getRainAmount() -> Double { defaults?.double(forKey: Keys.rainAmount) ?? 0.0 }
    static func getTemperatureMax() -> Double { defaults?.double(forKey: Keys.temperatureMax) ?? 0.0 }
    static func getTemperatureMin() -> Double { defaults?.double(forKey: Keys.temperatureMin) ?? 0.0 }
    static func getHumidity() -> Double { defaults?.double(forKey: Keys.humidity) ?? 0.0 }
    static func getWindSpeedMax() -> Double { defaults?.double(forKey: Keys.windSpeedMax) ?? 0.0 }
    static func getPM25() -> Double { defaults?.double(forKey: Keys.pm25) ?? 0.0 }
    static func getLightLevel() -> Double { defaults?.double(forKey: Keys.lightLevel) ?? 0.0 }
    static func getAQI() -> Double { defaults?.double(forKey: Keys.aqi) ?? 0.0 }
    static func getWindDirection() -> String { defaults?.string(forKey: Keys.windDirection) ?? "" }
    static func getPressure() -> Double { defaults?.double(forKey: Keys.pressure) ?? 0.0 }
    static func getTotalEventsProcessed() -> UInt64 { UInt64(defaults?.integer(forKey: Keys.totalEventsProcessed) ?? 0) }
    static func getLastUpdated() -> Date? { defaults?.object(forKey: Keys.lastUpdated) as? Date }

    private static func trend(forKey key: String) -> Trend {
        guard let rawValue = defaults?.string(forKey: key),
              let trend = Trend(rawValue: rawValue) else {
            return .stable
        }
        return trend
    }

    static func getTemperatureTrend() -> Trend { trend(forKey: Keys.temperatureTrend) }
    static func getWindSpeedTrend() -> Trend { trend(forKey: Keys.windSpeedTrend) }
    static func getHumidityTrend() -> Trend { trend(forKey: Keys.humidityTrend) }
    static func getPM25Trend() -> Trend { trend(forKey: Keys.pm25Trend) }
    static func getLightLevelTrend() -> Trend { trend(forKey: Keys.lightLevelTrend) }
    static func getPressureTrend() -> Trend { trend(forKey: Keys.pressureTrend) }

    static func getSensorSnapshot() -> SensorSnapshot {
        SensorSnapshot(
            outsideTemperature: getOutsideTemperature(),
            windSpeed: getWindSpeed(),
            rainAmount: getRainAmount(),
            temperatureMax: getTemperatureMax(),
            temperatureMin: getTemperatureMin(),
            humidity: getHumidity(),
            windSpeedMax: getWindSpeedMax(),
            pm25: getPM25(),
            lightLevel: getLightLevel(),
            aqi: getAQI(),
            windDirection: getWindDirection(),
            pressure: getPressure(),
            lastUpdated: getLastUpdated() ?? Date(),
            temperatureTrend: getTemperatureTrend(),
            windSpeedTrend: getWindSpeedTrend(),
            humidityTrend: getHumidityTrend(),
            pm25Trend: getPM25Trend(),
            lightLevelTrend: getLightLevelTrend(),
            pressureTrend: getPressureTrend()
        )
    }

    static func getServerHostname() -> String? { defaults?.string(forKey: Keys.serverHostname) }
    static func getServerPort() -> Int { defaults?.integer(forKey: Keys.serverPort) ?? 443 }
    static func getServerUseTLS() -> Bool { defaults?.bool(forKey: Keys.serverUseTLS) ?? true }
    static func getAuthToken() -> String? { defaults?.string(forKey: Keys.authToken) }
    static func getTemperatureEntity() -> String? { defaults?.string(forKey: Keys.temperatureEntity) }
    static func getWindSpeedEntity() -> String? { defaults?.string(forKey: Keys.windSpeedEntity) }
    static func getRainAmountEntity() -> String? { defaults?.string(forKey: Keys.rainAmountEntity) }
    static func getTemperatureMaxEntity() -> String? { defaults?.string(forKey: Keys.temperatureMaxEntity) }
    static func getTemperatureMinEntity() -> String? { defaults?.string(forKey: Keys.temperatureMinEntity) }
    static func getHumidityEntity() -> String? { defaults?.string(forKey: Keys.humidityEntity) }
    static func getWindSpeedMaxEntity() -> String? { defaults?.string(forKey: Keys.windSpeedMaxEntity) }
    static func getPM25Entity() -> String? { defaults?.string(forKey: Keys.pm25Entity) }
    static func getLightLevelEntity() -> String? { defaults?.string(forKey: Keys.lightLevelEntity) }
    static func getAQIEntity() -> String? { defaults?.string(forKey: Keys.aqiEntity) }
    static func getWindDirectionEntity() -> String? { defaults?.string(forKey: Keys.windDirectionEntity) }
    static func getPressureEntity() -> String? { defaults?.string(forKey: Keys.pressureEntity) }

    static func hasConfiguration() -> Bool {
        guard let hostname = getServerHostname(),
              let token = getAuthToken(),
              let _ = getTemperatureEntity(),
              let _ = getWindSpeedEntity(),
              let _ = getRainAmountEntity(),
              !hostname.isEmpty,
              !token.isEmpty else {
            return false
        }
        return true
    }

    private static func updateLastUpdated() {
        defaults?.set(Date(), forKey: Keys.lastUpdated)
    }

    #if DEBUG
    /// Removes any persisted values. Intended for testing only.
    static func resetForTesting() {
        defaults?.removePersistentDomain(forName: appGroupIdentifier)
    }
    #endif
}

// MARK: - Snapshot Model

struct SensorSnapshot: Codable, Sendable {
    let outsideTemperature: Double
    let windSpeed: Double
    let rainAmount: Double
    let temperatureMax: Double
    let temperatureMin: Double
    let humidity: Double
    let windSpeedMax: Double
    let pm25: Double
    let lightLevel: Double
    let aqi: Double
    let windDirection: String
    let pressure: Double
    let lastUpdated: Date
    let temperatureTrend: Trend
    let windSpeedTrend: Trend
    let humidityTrend: Trend
    let pm25Trend: Trend
    let lightLevelTrend: Trend
    let pressureTrend: Trend
}
