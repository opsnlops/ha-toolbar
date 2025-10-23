
import Foundation
import OSLog
import SwiftUI
import WidgetKit


@MainActor
public class MonitoredSensors: ObservableObject {

    let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "MonitoredSensors")

    // We only want one of these
    static let shared = MonitoredSensors()

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
    @Published public var pressure: Double = 0.0

    // Trend tracking for sensors
    private var temperatureHistory = TrendHistory()
    private var windSpeedHistory = TrendHistory()
    private var humidityHistory = TrendHistory()
    private var pm25History = TrendHistory()
    private var lightLevelHistory = TrendHistory()
    private var pressureHistory = TrendHistory()

    // Thresholds for slope-based trend detection (change per minute)
    // These detect gradual trends more effectively than point-to-point comparison
    private let temperatureThreshold: Double = 0.01   // ±0.01°F/min (~0.3°F over 30 min)
    private let windSpeedThreshold: Double = 0.02     // ±0.02 mph/min (~0.6 mph over 30 min)
    private let humidityThreshold: Double = 0.05      // ±0.05%/min (~1.5% over 30 min)
    private let pm25Threshold: Double = 0.1           // ±0.1 µg/m³/min (~3 µg/m³ over 30 min)
    private let lightLevelThreshold: Double = 2.0     // ±2 lux/min (~60 lux over 30 min)
    private let pressureThreshold: Double = 0.03      // ±0.03 hPa/min (~1 hPa over 30 min)

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

    public var pressureTrend: Trend {
        pressureHistory.calculateTrend(threshold: pressureThreshold)
    }

    @MainActor
    public func incrementTotalEventsProcessed() {
        self.totalEventsProcessed += 1
        SharedSensorStorage.saveTotalEventsProcessed(self.totalEventsProcessed)
    }


    @MainActor
    func updateOutsideTemperature(_ temperature: Double) {

        // Only send a notification if things have actually changed
        if temperature != self.outsideTemperature {
            self.outsideTemperature = temperature
            temperatureHistory.addDataPoint(value: temperature)
            SharedSensorStorage.saveOutsideTemperature(temperature)
            SharedSensorStorage.saveTemperatureTrend(temperatureTrend)
            reloadWidgets()
        }
    }

    @MainActor
    func updateWindSpeed(_ windSpeed: Double) {
        if windSpeed != self.windSpeed {
            self.windSpeed = windSpeed
            windSpeedHistory.addDataPoint(value: windSpeed)
            SharedSensorStorage.saveWindSpeed(windSpeed)
            SharedSensorStorage.saveWindSpeedTrend(windSpeedTrend)
            reloadWidgets()
        }

    }

    @MainActor
    func updateRainAmount(_ rainAmount: Double) {
        if rainAmount != self.rainAmount {
            self.rainAmount = rainAmount
            SharedSensorStorage.saveRainAmount(rainAmount)
            reloadWidgets()
        }
    }

    @MainActor
    func updateTemperatureMax(_ temperatureMax: Double) {
        if temperatureMax != self.temperatureMax {
            self.temperatureMax = temperatureMax
            SharedSensorStorage.saveTemperatureMax(temperatureMax)
            reloadWidgets()
        }
    }

    @MainActor
    func updateTemperatureMin(_ temperatureMin: Double) {
        if temperatureMin != self.temperatureMin {
            self.temperatureMin = temperatureMin
            SharedSensorStorage.saveTemperatureMin(temperatureMin)
            reloadWidgets()
        }
    }

    @MainActor
    func updateHumidity(_ humidity: Double) {
        if humidity != self.humidity {
            self.humidity = humidity
            humidityHistory.addDataPoint(value: humidity)
            SharedSensorStorage.saveHumidity(humidity)
            SharedSensorStorage.saveHumidityTrend(humidityTrend)
            reloadWidgets()
        }
    }

    @MainActor
    func updateWindSpeedMax(_ windSpeedMax: Double) {
        if windSpeedMax != self.windSpeedMax {
            self.windSpeedMax = windSpeedMax
            SharedSensorStorage.saveWindSpeedMax(windSpeedMax)
            reloadWidgets()
        }
    }

    @MainActor
    func updatePM25(_ pm25: Double) {
        if pm25 != self.pm25 {
            self.pm25 = pm25
            pm25History.addDataPoint(value: pm25)
            SharedSensorStorage.savePM25(pm25)
            SharedSensorStorage.savePM25Trend(pm25Trend)
            reloadWidgets()
        }
    }

    @MainActor
    func updateLightLevel(_ lightLevel: Double) {
        if lightLevel != self.lightLevel {
            self.lightLevel = lightLevel
            lightLevelHistory.addDataPoint(value: lightLevel)
            SharedSensorStorage.saveLightLevel(lightLevel)
            SharedSensorStorage.saveLightLevelTrend(lightLevelTrend)
            reloadWidgets()
        }
    }

    @MainActor
    func updateAQI(_ aqi: Double) {
        if aqi != self.aqi {
            self.aqi = aqi
            SharedSensorStorage.saveAQI(aqi)
            reloadWidgets()
        }
    }

    @MainActor
    func updateWindDirection(_ windDirection: String) {
        if windDirection != self.windDirection {
            self.windDirection = windDirection
            SharedSensorStorage.saveWindDirection(windDirection)
            reloadWidgets()
        }
    }

    @MainActor
    func updatePressure(_ pressure: Double) {
        if pressure != self.pressure {
            self.pressure = pressure
            pressureHistory.addDataPoint(value: pressure)
            SharedSensorStorage.savePressure(pressure)
            SharedSensorStorage.savePressureTrend(pressureTrend)
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
