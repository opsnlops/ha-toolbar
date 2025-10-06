import SwiftUI
import WidgetKit

struct HomeAssistantWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    let entry: SensorTimelineEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(snapshot: entry.snapshot)
                .widgetAccentable()
        case .systemMedium:
            MediumWidgetView(snapshot: entry.snapshot, displayStyle: entry.configuration.displayStyle)
                .widgetAccentable()
        case .systemLarge, .systemExtraLarge:
            LargeWidgetView(snapshot: entry.snapshot)
                .widgetAccentable()
        #if os(iOS)
        case .accessoryCircular:
            AccessoryCircularView(snapshot: entry.snapshot)
        case .accessoryRectangular:
            AccessoryRectangularView(snapshot: entry.snapshot)
        case .accessoryInline:
            AccessoryInlineView(snapshot: entry.snapshot)
        #endif
        default:
            LargeWidgetView(snapshot: entry.snapshot)
                .widgetAccentable()
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let snapshot: SensorSnapshot

    var temperatureColor: Color {
        switch snapshot.outsideTemperature {
        case ..<32: return .blue
        case 32..<60: return .cyan
        case 60..<75: return .green
        case 75..<85: return .orange
        default: return .red
        }
    }

    var gaugeProgress: Double {
        // Use min/max temps if available, otherwise fallback to 0-100
        guard snapshot.temperatureMin > 0 && snapshot.temperatureMax > 0 else {
            return min(snapshot.outsideTemperature / 100, 1.0)
        }

        let range = snapshot.temperatureMax - snapshot.temperatureMin
        guard range > 0 else { return 0.5 }

        let progress = (snapshot.outsideTemperature - snapshot.temperatureMin) / range
        return max(0, min(1.0, progress))
    }

    var body: some View {
        VStack(spacing: 4) {
            // Temperature gauge
            ZStack {
                Circle()
                    .stroke(temperatureColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(gaugeProgress))
                    .stroke(temperatureColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 20))
                        .foregroundStyle(temperatureColor)
                    Text(String(format: "%.0f", snapshot.outsideTemperature))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(temperatureColor)
                    Text("°F")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Compact stats
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    Image(systemName: "wind")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f", snapshot.windSpeed))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }

                HStack(spacing: 3) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                    Text(String(format: "%.1f", snapshot.rainAmount))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }

                if snapshot.humidity > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "humidity.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.teal)
                        Text(String(format: "%.0f", snapshot.humidity))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let snapshot: SensorSnapshot
    let displayStyle: DisplayStyleOption?

    var temperatureColor: Color {
        switch snapshot.outsideTemperature {
        case ..<32: return .blue
        case 32..<60: return .cyan
        case 60..<75: return .green
        case 75..<85: return .orange
        default: return .red
        }
    }

    var windColor: Color {
        switch snapshot.windSpeed {
        case ..<10: return .green
        case 10..<20: return .yellow
        case 20..<30: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: Temperature
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(temperatureColor)
                    Text("Temperature")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", snapshot.outsideTemperature))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(temperatureColor)
                    Text("°F")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                // High/Low temps if available
                if snapshot.temperatureMax > 0 || snapshot.temperatureMin > 0 {
                    HStack(spacing: 8) {
                        if snapshot.temperatureMax > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 9, weight: .semibold))
                                Text(String(format: "%.0f°", snapshot.temperatureMax))
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.orange.opacity(0.8))
                        }

                        if snapshot.temperatureMin > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 9, weight: .semibold))
                                Text(String(format: "%.0f°", snapshot.temperatureMin))
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.cyan.opacity(0.8))
                        }
                    }
                }
            }
            .padding()

            Divider()
                .opacity(0.2)

            // Right: Wind, Rain & Humidity
            VStack(spacing: 12) {
                SimpleSensorRow(
                    icon: "wind",
                    label: "Wind Speed",
                    value: String(format: "%.1f", snapshot.windSpeed),
                    unit: "mph",
                    color: windColor
                )

                SimpleSensorRow(
                    icon: "drop.fill",
                    label: "Rain Today",
                    value: String(format: "%.2f", snapshot.rainAmount),
                    unit: "mm",
                    color: .blue
                )

                if snapshot.humidity > 0 {
                    SimpleSensorRow(
                        icon: "humidity.fill",
                        label: "Humidity",
                        value: String(format: "%.0f", snapshot.humidity),
                        unit: "%",
                        color: .teal
                    )
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Simple Sensor Row (no progress bar)
struct SimpleSensorRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


// MARK: - Large Widget

struct LargeWidgetView: View {
    let snapshot: SensorSnapshot

    var temperatureColor: Color {
        switch snapshot.outsideTemperature {
        case ..<32: return .blue
        case 32..<60: return .cyan
        case 60..<75: return .green
        case 75..<85: return .orange
        default: return .red
        }
    }

    var windColor: Color {
        switch snapshot.windSpeed {
        case ..<10: return .green
        case 10..<20: return .yellow
        case 20..<30: return .orange
        default: return .red
        }
    }

    var aqiColor: Color {
        switch snapshot.aqi {
        case ..<51: return .green
        case 51..<101: return .yellow
        case 101..<151: return .orange
        case 151..<201: return .red
        default: return .purple
        }
    }

    var pm25Color: Color {
        switch snapshot.pm25 {
        case ..<12: return .green
        case 12..<35: return .yellow
        case 35..<55: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "house.fill")
                    .font(.system(size: 12))
                Text("Home Assistant")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 12)

            // Main content grid
            VStack(spacing: 16) {
                // Temperature - Large feature
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(temperatureColor.opacity(0.2), lineWidth: 6)
                            .frame(width: 70, height: 70)

                        Circle()
                            .trim(from: 0, to: CGFloat(min(snapshot.outsideTemperature / 100, 1.0)))
                            .stroke(temperatureColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 16))
                                .foregroundStyle(temperatureColor)
                            Text(String(format: "%.0f", snapshot.outsideTemperature))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(temperatureColor)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Outside Temperature")
                            .font(.system(size: 14, weight: .semibold))

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", snapshot.outsideTemperature))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(temperatureColor)
                            Text("°F")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }

                        // High/Low temps
                        if snapshot.temperatureMax > 0 || snapshot.temperatureMin > 0 {
                            HStack(spacing: 10) {
                                if snapshot.temperatureMax > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 10, weight: .semibold))
                                        Text(String(format: "%.0f°", snapshot.temperatureMax))
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(.orange.opacity(0.8))
                                }

                                if snapshot.temperatureMin > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 10, weight: .semibold))
                                        Text(String(format: "%.0f°", snapshot.temperatureMin))
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(.cyan.opacity(0.8))
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding()

                //Wind & Air Quality Row
                HStack(spacing: 10) {
                    CompactSensorCard(
                        icon: "wind",
                        label: "Wind",
                        value: String(format: "%.1f", snapshot.windSpeed),
                        unit: "mph",
                        detail: !snapshot.windDirection.isEmpty ? snapshot.windDirection : nil,
                        color: windColor
                    )

                    if snapshot.windSpeedMax > 0 {
                        CompactSensorCard(
                            icon: "wind.circle",
                            label: "Max Gust",
                            value: String(format: "%.1f", snapshot.windSpeedMax),
                            unit: "mph",
                            detail: nil,
                            color: windColor.opacity(0.7)
                        )
                    }

                    CompactSensorCard(
                        icon: "aqi.medium",
                        label: "AQI",
                        value: String(format: "%.0f", snapshot.aqi),
                        unit: "",
                        detail: nil,
                        color: aqiColor
                    )

                    CompactSensorCard(
                        icon: "circle.hexagongrid",
                        label: "PM2.5",
                        value: String(format: "%.0f", snapshot.pm25),
                        unit: "µg/m³",
                        detail: nil,
                        color: pm25Color
                    )
                }

                // Rain & Environmental Row
                HStack(spacing: 10) {
                    CompactSensorCard(
                        icon: "drop.fill",
                        label: "Rain",
                        value: String(format: "%.2f", snapshot.rainAmount),
                        unit: "mm",
                        detail: nil,
                        color: .blue
                    )

                    if snapshot.humidity > 0 {
                        CompactSensorCard(
                            icon: "humidity.fill",
                            label: "Humidity",
                            value: String(format: "%.0f", snapshot.humidity),
                            unit: "%",
                            detail: nil,
                            color: .teal
                        )
                    }

                    if snapshot.lightLevel > 0 {
                        CompactSensorCard(
                            icon: "sun.max.fill",
                            label: "Light",
                            value: String(format: "%.0f", snapshot.lightLevel),
                            unit: "lux",
                            detail: nil,
                            color: .yellow
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Simple Sensor Card (no background, no progress bar)
struct SimpleSensorCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Compact Sensor Card (for data-dense large widget)
struct CompactSensorCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let detail: String?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            if let detail = detail {
                Text(detail)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }
}

// MARK: - iOS Lock Screen Widgets

#if os(iOS)
struct AccessoryCircularView: View {
    let snapshot: SensorSnapshot

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(snapshot.outsideTemperature, specifier: "%.0f")°")
                    .font(.system(size: 20, weight: .bold))
                Text("F")
                    .font(.caption2)
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let snapshot: SensorSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Home Assistant")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack {
                Text("🌡️ \(snapshot.outsideTemperature, specifier: "%.1f")°F")
                    .font(.body)
                Spacer()
            }
            HStack(spacing: 12) {
                Text("💨 \(snapshot.windSpeed, specifier: "%.0f")")
                    .font(.caption)
                Text("🌧️ \(snapshot.rainAmount, specifier: "%.1f")")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
}

struct AccessoryInlineView: View {
    let snapshot: SensorSnapshot

    var body: some View {
        Text("🌡️ \(snapshot.outsideTemperature, specifier: "%.1f")°F")
    }
}
#endif

// MARK: - Preview

#Preview(as: .systemSmall) {
    HomeAssistantWidget()
} timeline: {
    SensorTimelineEntry(
        date: Date(),
        snapshot: SensorSnapshot(
            outsideTemperature: 72.5,
            windSpeed: 5.2,
            rainAmount: 0.15,
            temperatureMax: 78.0,
            temperatureMin: 65.0,
            humidity: 60.0,
            windSpeedMax: 12.0,
            pm25: 8.0,
            lightLevel: 450.0,
            aqi: 42.0,
            windDirection: "NW",
            lastUpdated: Date()
        ),
        configuration: SensorConfigurationIntent()
    )
}

#Preview(as: .systemMedium) {
    HomeAssistantWidget()
} timeline: {
    SensorTimelineEntry(
        date: Date(),
        snapshot: SensorSnapshot(
            outsideTemperature: 72.5,
            windSpeed: 5.2,
            rainAmount: 0.15,
            temperatureMax: 78.0,
            temperatureMin: 65.0,
            humidity: 60.0,
            windSpeedMax: 12.0,
            pm25: 8.0,
            lightLevel: 450.0,
            aqi: 42.0,
            windDirection: "NW",
            lastUpdated: Date()
        ),
        configuration: SensorConfigurationIntent()
    )
}

// MARK: - CarPlay Widget View

#if os(iOS)
struct CarPlayWidgetView: View {
    let entry: SensorTimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("🌡️")
                    .font(.title3)
                Text("\(entry.snapshot.outsideTemperature, specifier: "%.0f")°F")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("💨")
                        .font(.caption)
                    Text("\(entry.snapshot.windSpeed, specifier: "%.0f")")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                if entry.snapshot.rainAmount > 0 {
                    HStack(spacing: 4) {
                        Text("🌧️")
                            .font(.caption)
                        Text("\(entry.snapshot.rainAmount, specifier: "%.1f")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
#endif

// MARK: - Previews

#Preview(as: .systemLarge) {
    HomeAssistantWidget()
} timeline: {
    SensorTimelineEntry(
        date: Date(),
        snapshot: SensorSnapshot(
            outsideTemperature: 72.5,
            windSpeed: 5.2,
            rainAmount: 0.15,
            temperatureMax: 78.0,
            temperatureMin: 65.0,
            humidity: 60.0,
            windSpeedMax: 12.0,
            pm25: 8.0,
            lightLevel: 450.0,
            aqi: 42.0,
            windDirection: "NW",
            lastUpdated: Date()
        ),
        configuration: SensorConfigurationIntent()
    )
}
