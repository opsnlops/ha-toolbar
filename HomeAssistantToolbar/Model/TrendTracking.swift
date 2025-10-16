import Foundation
import SwiftUI

/// A single data point with timestamp for trend calculation
struct DataPoint: Codable {
    let value: Double
    let timestamp: Date
}

/// Manages historical data points for trend calculation
class TrendHistory: Codable {
    private var dataPoints: [DataPoint] = []
    private let maxDataPoints = 20  // Keep ~20 points (enough for 15-min comparison with 1-min updates)

    /// Adds a new data point
    func addDataPoint(value: Double) {
        let point = DataPoint(value: value, timestamp: Date())
        dataPoints.append(point)

        // Remove old data points (keep last hour of data)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        dataPoints.removeAll { $0.timestamp < oneHourAgo }

        // Also enforce max count to prevent unbounded growth
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst(dataPoints.count - maxDataPoints)
        }
    }

    /// Calculate trend by comparing current value to value from 15 minutes ago
    func calculateTrend(threshold: Double) -> Trend {
        guard !dataPoints.isEmpty else { return .stable }

        let currentValue = dataPoints.last!.value
        let fifteenMinutesAgo = Date().addingTimeInterval(-15 * 60)  // 15 minutes

        // Find the closest data point to 15 minutes ago
        let historicalPoint = dataPoints
            .filter { $0.timestamp <= fifteenMinutesAgo }
            .last

        // If we don't have data from 15 minutes ago yet, return stable
        guard let historical = historicalPoint else { return .stable }

        let difference = currentValue - historical.value

        if abs(difference) < threshold {
            return .stable
        } else if difference > 0 {
            return .up
        } else {
            return .down
        }
    }

    /// Returns the current value (most recent data point)
    var currentValue: Double? {
        dataPoints.last?.value
    }

    /// Returns all data points for serialization
    func getDataPoints() -> [DataPoint] {
        return dataPoints
    }

    /// Initializes from existing data points (for deserialization)
    init(dataPoints: [DataPoint] = []) {
        self.dataPoints = dataPoints
    }
}
