
import Foundation
import OSLog
import SwiftUI
import WidgetKit


public class MonitoredSensors: ObservableObject {

    let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "MonitoredSensors")

    // We only want one of these
    static let shared = MonitoredSensors()

    private let sharedStorage = SharedSensorStorage.shared

    @Published public var totalEventsProcessed: UInt64 = 0
    @Published public var outsideTemperature: Double = 0.0
    @Published public var windSpeed: Double = 0.0
    @Published public var rainAmount: Double = 0.0
    @Published public var temperatureMax: Double = 0.0
    @Published public var temperatureMin: Double = 0.0
    @Published public var humidity: Double = 0.0
    @Published public var windSpeedMax: Double = 0.0
    @Published public var pm25: Double = 0.0
    @Published public var lightLevel: Double = 0.0
    @Published public var aqi: Double = 0.0
    @Published public var windDirection: String = ""

    // Trend tracking for sensors
    private var temperatureHistory = TrendHistory()
    private var windSpeedHistory = TrendHistory()
    private var humidityHistory = TrendHistory()
    private var pm25History = TrendHistory()
    private var lightLevelHistory = TrendHistory()
    private var aqiHistory = TrendHistory()

    // Thresholds for determining if a change is significant
    private let temperatureThreshold: Double = 0.25  // ±0.25°F
    private let windSpeedThreshold: Double = 0.5    // ±0.5 mph
    private let humidityThreshold: Double = 2.0     // ±2%
    private let pm25Threshold: Double = 5.0         // ±5 µg/m³
    private let aqiThreshold: Double = 5.0          // ±5 AQI
    private let lightLevelThreshold: Double = 100.0 // ±100 lux

    // Computed properties for trends
    public var temperatureTrend: Trend {
        temperatureHistory.calculateTrend(threshold: temperatureThreshold)
    }

    public var windSpeedTrend: Trend {
        windSpeedHistory.calculateTrend(threshold: windSpeedThreshold)
    }

    public var humidityTrend: Trend {
        humidityHistory.calculateTrend(threshold: humidityThreshold)
    }

    public var pm25Trend: Trend {
        pm25History.calculateTrend(threshold: pm25Threshold)
    }

    public var lightLevelTrend: Trend {
        lightLevelHistory.calculateTrend(threshold: lightLevelThreshold)
    }

    public var aqiTrend: Trend {
        aqiHistory.calculateTrend(threshold: aqiThreshold)
    }

    @MainActor
    public func incrementTotalEventsProcessed() {
        self.totalEventsProcessed += 1
        sharedStorage.saveTotalEventsProcessed(self.totalEventsProcessed)
    }


    @MainActor
    func updateOutsideTemperature(_ temperature: Double) {

        // Only send a notification if things have actually changed
        if temperature != self.outsideTemperature {
            self.outsideTemperature = temperature
            temperatureHistory.addDataPoint(value: temperature)
            sharedStorage.saveOutsideTemperature(temperature)
            sharedStorage.saveTemperatureTrend(temperatureTrend)
            reloadWidgets()
        }
    }

    @MainActor
    func updateWindSpeed(_ windSpeed: Double) {
        if windSpeed != self.windSpeed {
            self.windSpeed = windSpeed
            windSpeedHistory.addDataPoint(value: windSpeed)
            sharedStorage.saveWindSpeed(windSpeed)
            sharedStorage.saveWindSpeedTrend(windSpeedTrend)
            reloadWidgets()
        }

    }

    @MainActor
    func updateRainAmount(_ rainAmount: Double) {
        if rainAmount != self.rainAmount {
            self.rainAmount = rainAmount
            sharedStorage.saveRainAmount(rainAmount)
            reloadWidgets()
        }
    }

    @MainActor
    func updateTemperatureMax(_ temperatureMax: Double) {
        if temperatureMax != self.temperatureMax {
            self.temperatureMax = temperatureMax
            sharedStorage.saveTemperatureMax(temperatureMax)
            reloadWidgets()
        }
    }

    @MainActor
    func updateTemperatureMin(_ temperatureMin: Double) {
        if temperatureMin != self.temperatureMin {
            self.temperatureMin = temperatureMin
            sharedStorage.saveTemperatureMin(temperatureMin)
            reloadWidgets()
        }
    }

    @MainActor
    func updateHumidity(_ humidity: Double) {
        if humidity != self.humidity {
            self.humidity = humidity
            humidityHistory.addDataPoint(value: humidity)
            sharedStorage.saveHumidity(humidity)
            sharedStorage.saveHumidityTrend(humidityTrend)
            reloadWidgets()
        }
    }

    @MainActor
    func updateWindSpeedMax(_ windSpeedMax: Double) {
        if windSpeedMax != self.windSpeedMax {
            self.windSpeedMax = windSpeedMax
            sharedStorage.saveWindSpeedMax(windSpeedMax)
            reloadWidgets()
        }
    }

    @MainActor
    func updatePM25(_ pm25: Double) {
        if pm25 != self.pm25 {
            self.pm25 = pm25
            pm25History.addDataPoint(value: pm25)
            sharedStorage.savePM25(pm25)
            sharedStorage.savePM25Trend(pm25Trend)
            reloadWidgets()
        }
    }

    @MainActor
    func updateLightLevel(_ lightLevel: Double) {
        if lightLevel != self.lightLevel {
            self.lightLevel = lightLevel
            lightLevelHistory.addDataPoint(value: lightLevel)
            sharedStorage.saveLightLevel(lightLevel)
            sharedStorage.saveLightLevelTrend(lightLevelTrend)
            reloadWidgets()
        }
    }

    @MainActor
    func updateAQI(_ aqi: Double) {
        if aqi != self.aqi {
            self.aqi = aqi
            aqiHistory.addDataPoint(value: aqi)
            sharedStorage.saveAQI(aqi)
            sharedStorage.saveAQITrend(aqiTrend)
            reloadWidgets()
        }
    }

    @MainActor
    func updateWindDirection(_ windDirection: String) {
        if windDirection != self.windDirection {
            self.windDirection = windDirection
            sharedStorage.saveWindDirection(windDirection)
            reloadWidgets()
        }
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

}


extension MonitoredSensors {
    public static func mock() -> MonitoredSensors {
        return MonitoredSensors()
    }
}
