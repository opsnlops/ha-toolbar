import Foundation

/// Manages shared storage for sensor data between the main app and widget extension
class SharedSensorStorage {

    static let shared = SharedSensorStorage()

    // App Group identifier - make sure this matches your App Group configuration
    private let appGroupIdentifier = "group.io.opsnlops.HomeAssistantToolbar"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // Keys for shared storage
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
        static let lastUpdated = "shared.lastUpdated"
        static let totalEventsProcessed = "shared.totalEventsProcessed"

        // Configuration keys
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
    }

    // MARK: - Write Methods

    func saveOutsideTemperature(_ temperature: Double) {
        sharedDefaults?.set(temperature, forKey: Keys.outsideTemperature)
        updateLastUpdated()
    }

    func saveWindSpeed(_ windSpeed: Double) {
        sharedDefaults?.set(windSpeed, forKey: Keys.windSpeed)
        updateLastUpdated()
    }

    func saveRainAmount(_ rainAmount: Double) {
        sharedDefaults?.set(rainAmount, forKey: Keys.rainAmount)
        updateLastUpdated()
    }

    func saveTemperatureMax(_ temperatureMax: Double) {
        sharedDefaults?.set(temperatureMax, forKey: Keys.temperatureMax)
        updateLastUpdated()
    }

    func saveTemperatureMin(_ temperatureMin: Double) {
        sharedDefaults?.set(temperatureMin, forKey: Keys.temperatureMin)
        updateLastUpdated()
    }

    func saveHumidity(_ humidity: Double) {
        sharedDefaults?.set(humidity, forKey: Keys.humidity)
        updateLastUpdated()
    }

    func saveWindSpeedMax(_ windSpeedMax: Double) {
        sharedDefaults?.set(windSpeedMax, forKey: Keys.windSpeedMax)
        updateLastUpdated()
    }

    func savePM25(_ pm25: Double) {
        sharedDefaults?.set(pm25, forKey: Keys.pm25)
        updateLastUpdated()
    }

    func saveLightLevel(_ lightLevel: Double) {
        sharedDefaults?.set(lightLevel, forKey: Keys.lightLevel)
        updateLastUpdated()
    }

    func saveAQI(_ aqi: Double) {
        sharedDefaults?.set(aqi, forKey: Keys.aqi)
        updateLastUpdated()
    }

    func saveWindDirection(_ windDirection: String) {
        sharedDefaults?.set(windDirection, forKey: Keys.windDirection)
        updateLastUpdated()
    }

    func saveTotalEventsProcessed(_ count: UInt64) {
        sharedDefaults?.set(count, forKey: Keys.totalEventsProcessed)
    }

    private func updateLastUpdated() {
        sharedDefaults?.set(Date(), forKey: Keys.lastUpdated)
    }

    // MARK: - Read Methods

    func getOutsideTemperature() -> Double {
        sharedDefaults?.double(forKey: Keys.outsideTemperature) ?? 0.0
    }

    func getWindSpeed() -> Double {
        sharedDefaults?.double(forKey: Keys.windSpeed) ?? 0.0
    }

    func getRainAmount() -> Double {
        sharedDefaults?.double(forKey: Keys.rainAmount) ?? 0.0
    }

    func getTemperatureMax() -> Double {
        sharedDefaults?.double(forKey: Keys.temperatureMax) ?? 0.0
    }

    func getTemperatureMin() -> Double {
        sharedDefaults?.double(forKey: Keys.temperatureMin) ?? 0.0
    }

    func getHumidity() -> Double {
        sharedDefaults?.double(forKey: Keys.humidity) ?? 0.0
    }

    func getWindSpeedMax() -> Double {
        sharedDefaults?.double(forKey: Keys.windSpeedMax) ?? 0.0
    }

    func getPM25() -> Double {
        sharedDefaults?.double(forKey: Keys.pm25) ?? 0.0
    }

    func getLightLevel() -> Double {
        sharedDefaults?.double(forKey: Keys.lightLevel) ?? 0.0
    }

    func getAQI() -> Double {
        sharedDefaults?.double(forKey: Keys.aqi) ?? 0.0
    }

    func getWindDirection() -> String {
        sharedDefaults?.string(forKey: Keys.windDirection) ?? ""
    }

    func getTotalEventsProcessed() -> UInt64 {
        UInt64(sharedDefaults?.integer(forKey: Keys.totalEventsProcessed) ?? 0)
    }

    func getLastUpdated() -> Date? {
        sharedDefaults?.object(forKey: Keys.lastUpdated) as? Date
    }

    // MARK: - Snapshot Data

    /// Returns all sensor data as a snapshot for widget timeline entries
    func getSensorSnapshot() -> SensorSnapshot {
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
            lastUpdated: getLastUpdated() ?? Date()
        )
    }

    // MARK: - Configuration Methods

    func saveConfiguration(hostname: String, port: Int, useTLS: Bool, authToken: String,
                          temperatureEntity: String, windSpeedEntity: String, rainAmountEntity: String,
                          temperatureMaxEntity: String, temperatureMinEntity: String, humidityEntity: String,
                          windSpeedMaxEntity: String, pm25Entity: String, lightLevelEntity: String,
                          aqiEntity: String, windDirectionEntity: String) {
        sharedDefaults?.set(hostname, forKey: Keys.serverHostname)
        sharedDefaults?.set(port, forKey: Keys.serverPort)
        sharedDefaults?.set(useTLS, forKey: Keys.serverUseTLS)
        sharedDefaults?.set(authToken, forKey: Keys.authToken)
        sharedDefaults?.set(temperatureEntity, forKey: Keys.temperatureEntity)
        sharedDefaults?.set(windSpeedEntity, forKey: Keys.windSpeedEntity)
        sharedDefaults?.set(rainAmountEntity, forKey: Keys.rainAmountEntity)
        sharedDefaults?.set(temperatureMaxEntity, forKey: Keys.temperatureMaxEntity)
        sharedDefaults?.set(temperatureMinEntity, forKey: Keys.temperatureMinEntity)
        sharedDefaults?.set(humidityEntity, forKey: Keys.humidityEntity)
        sharedDefaults?.set(windSpeedMaxEntity, forKey: Keys.windSpeedMaxEntity)
        sharedDefaults?.set(pm25Entity, forKey: Keys.pm25Entity)
        sharedDefaults?.set(lightLevelEntity, forKey: Keys.lightLevelEntity)
        sharedDefaults?.set(aqiEntity, forKey: Keys.aqiEntity)
        sharedDefaults?.set(windDirectionEntity, forKey: Keys.windDirectionEntity)
    }

    func getServerHostname() -> String? {
        sharedDefaults?.string(forKey: Keys.serverHostname)
    }

    func getServerPort() -> Int {
        sharedDefaults?.integer(forKey: Keys.serverPort) ?? 443
    }

    func getServerUseTLS() -> Bool {
        sharedDefaults?.bool(forKey: Keys.serverUseTLS) ?? true
    }

    func getAuthToken() -> String? {
        sharedDefaults?.string(forKey: Keys.authToken)
    }

    func getTemperatureEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.temperatureEntity)
    }

    func getWindSpeedEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.windSpeedEntity)
    }

    func getRainAmountEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.rainAmountEntity)
    }

    func getTemperatureMaxEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.temperatureMaxEntity)
    }

    func getTemperatureMinEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.temperatureMinEntity)
    }

    func getHumidityEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.humidityEntity)
    }

    func getWindSpeedMaxEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.windSpeedMaxEntity)
    }

    func getPM25Entity() -> String? {
        sharedDefaults?.string(forKey: Keys.pm25Entity)
    }

    func getLightLevelEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.lightLevelEntity)
    }

    func getAQIEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.aqiEntity)
    }

    func getWindDirectionEntity() -> String? {
        sharedDefaults?.string(forKey: Keys.windDirectionEntity)
    }

    func hasConfiguration() -> Bool {
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
}

// MARK: - Snapshot Model

struct SensorSnapshot: Codable {
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
    let lastUpdated: Date
}
