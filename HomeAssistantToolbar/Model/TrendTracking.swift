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
    private let maxDataPoints = 300  // Keep 1 hour of data (240 points at 15-sec intervals, plus buffer)

    /// Adds a new data point
    func addDataPoint(value: Double) {
        let point = DataPoint(value: value, timestamp: Date())
        dataPoints.append(point)

        // Remove old data points (keep last hour of data)
        let oneHourAgo = Date().addingTimeInterval(-3600)  // 1 hour = 3600 seconds
        dataPoints.removeAll { $0.timestamp < oneHourAgo }

        // Also enforce max count to prevent unbounded growth
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst(dataPoints.count - maxDataPoints)
        }
    }

    /// Calculate trend using linear regression across all data points
    /// This detects gradual trends better than single point comparison
    func calculateTrend(threshold: Double) -> Trend {
        guard dataPoints.count >= 2 else { return .stable }

        // Use all available data points for trend calculation
        let n = Double(dataPoints.count)

        // Convert timestamps to seconds from first point for x-axis
        let firstTimestamp = dataPoints.first!.timestamp.timeIntervalSince1970

        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0

        for point in dataPoints {
            let x = point.timestamp.timeIntervalSince1970 - firstTimestamp
            let y = point.value

            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }

        // Calculate slope using least squares linear regression
        // slope = (n*Σxy - Σx*Σy) / (n*Σx² - (Σx)²)
        let denominator = (n * sumX2) - (sumX * sumX)

        // Avoid division by zero
        guard denominator != 0 else { return .stable }

        let slope = ((n * sumXY) - (sumX * sumY)) / denominator

        // Convert slope to change per minute for easier interpretation
        // slope is currently change per second
        let slopePerMinute = slope * 60.0

        // Compare slope against threshold
        if abs(slopePerMinute) < threshold {
            return .stable
        } else if slopePerMinute > 0 {
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
