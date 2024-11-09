
import Foundation
import OSLog
import SwiftUI


public class MonitoredSensors: ObservableObject {

    let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "MonitoredSensors")

    // We only want one of these
    static let shared = MonitoredSensors()

    @Published public var totalEventsProcessed: UInt64 = 0
    @Published public var outsideTemperature: Double = 0.0
    @Published public var windSpeed: Double = 0.0
    @Published public var rainAmount: Double = 0.0

    @MainActor
    public func incrementTotalEventsProcessed() {
        self.totalEventsProcessed += 1
    }


    @MainActor
    func updateOutsideTemperature(_ temperature: Double) {

        // Only send a notification if things have actually changed
        if temperature != self.outsideTemperature {
            self.outsideTemperature = temperature
        }
    }

    @MainActor
    func updateWindSpeed(_ windSpeed: Double) {
        if windSpeed != self.windSpeed {
            self.windSpeed = windSpeed
        }

    }

    @MainActor
    func updateRainAmount(_ rainAmount: Double) {
        if rainAmount != self.rainAmount {
            self.rainAmount = rainAmount
        }
    }

}


extension MonitoredSensors {
    public static func mock() -> MonitoredSensors {
        return MonitoredSensors()
    }
}
