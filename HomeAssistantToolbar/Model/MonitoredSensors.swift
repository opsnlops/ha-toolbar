
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
            sharedStorage.saveOutsideTemperature(temperature)
            reloadWidgets()
        }
    }

    @MainActor
    func updateWindSpeed(_ windSpeed: Double) {
        if windSpeed != self.windSpeed {
            self.windSpeed = windSpeed
            sharedStorage.saveWindSpeed(windSpeed)
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
            sharedStorage.saveHumidity(humidity)
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
            sharedStorage.savePM25(pm25)
            reloadWidgets()
        }
    }

    @MainActor
    func updateLightLevel(_ lightLevel: Double) {
        if lightLevel != self.lightLevel {
            self.lightLevel = lightLevel
            sharedStorage.saveLightLevel(lightLevel)
            reloadWidgets()
        }
    }

    @MainActor
    func updateAQI(_ aqi: Double) {
        if aqi != self.aqi {
            self.aqi = aqi
            sharedStorage.saveAQI(aqi)
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
