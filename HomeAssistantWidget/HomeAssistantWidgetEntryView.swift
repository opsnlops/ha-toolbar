import SwiftUI
import WidgetKit

// MARK: - Helper Functions

func formatWithThousandsSeparator(_ value: Double) -> String {
    if value >= 1000 {
        let thousands = value / 1000.0
        return String(format: "%.1fk", thousands)
    } else {
        return String(format: "%.0f", value)
    }
}

struct HomeAssistantWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    let entry: SensorTimelineEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(snapshot: entry.snapshot)
                .widgetAccentable()
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .systemMedium:
            MediumWidgetView(snapshot: entry.snapshot, displayStyle: entry.configuration.displayStyle)
                .widgetAccentable()
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .systemLarge, .systemExtraLarge:
            LargeWidgetView(snapshot: entry.snapshot)
                .widgetAccentable()
                .containerBackground(for: .widget) {
                    Color.clear
                }
        #if os(iOS)
        case .accessoryCircular:
            AccessoryCircularView(snapshot: entry.snapshot)
                .widgetAccentable()
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .accessoryRectangular:
            AccessoryRectangularView(snapshot: entry.snapshot)
                .widgetAccentable()
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .accessoryInline:
            AccessoryInlineView(snapshot: entry.snapshot)
                .widgetAccentable()
                .containerBackground(for: .widget) {
                    Color.clear
                }
        #endif
        default:
            LargeWidgetView(snapshot: entry.snapshot)
                .widgetAccentable()
                .containerBackground(for: .widget) {
                    Color.clear
                }
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
        VStack(spacing: 0) {
            Spacer()

            // Temperature gauge
            ZStack {
                Circle()
                    .stroke(temperatureColor.opacity(0.2), lineWidth: 10)
                    .frame(width: 110, height: 110)

                Circle()
                    .trim(from: 0, to: CGFloat(gaugeProgress))
                    .stroke(temperatureColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 26))
                        .foregroundStyle(temperatureColor)
                    Text(String(format: "%.0f", snapshot.outsideTemperature))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(temperatureColor)
                    Text("°F")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
                .frame(maxHeight: 12)

            // High/Low temps if available
            if snapshot.temperatureMax > 0 || snapshot.temperatureMin > 0 {
                HStack(spacing: 12) {
                    if snapshot.temperatureMax > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 11, weight: .semibold))
                            Text(String(format: "%.0f°", snapshot.temperatureMax))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.orange.opacity(0.8))
                    }

                    if snapshot.temperatureMin > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 11, weight: .semibold))
                            Text(String(format: "%.0f°", snapshot.temperatureMin))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.cyan.opacity(0.8))
                    }
                }
            }

            Spacer()
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

    var pm25Color: Color {
        switch snapshot.pm25 {
        case ..<12: return .green
        case 12..<35: return .yellow
        case 35..<55: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: Temperature
            VStack(alignment: .center, spacing: 8) {
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
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()
                .opacity(0.2)

            // Right: 2x3 Grid of sensors
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    CompactSensorBox(
                        icon: "wind",
                        label: "Wind",
                        value: String(format: "%.1f", snapshot.windSpeed),
                        unit: "mph",
                        color: windColor
                    )

                    if snapshot.windSpeedMax > 0 {
                        CompactSensorBox(
                            icon: "wind.circle",
                            label: "Gust",
                            value: String(format: "%.1f", snapshot.windSpeedMax),
                            unit: "mph",
                            color: windColor.opacity(0.7)
                        )
                    }
                }

                HStack(spacing: 10) {
                    CompactSensorBox(
                        icon: "drop.fill",
                        label: "Rain",
                        value: String(format: "%.1f", snapshot.rainAmount),
                        unit: "mm",
                        color: .blue
                    )

                    if snapshot.pm25 > 0 {
                        CompactSensorBox(
                            icon: "circle.hexagongrid",
                            label: "PM2.5",
                            value: String(format: "%.0f", snapshot.pm25),
                            unit: "µg",
                            color: pm25Color
                        )
                    }
                }

                if snapshot.humidity > 0 {
                    HStack(spacing: 10) {
                        CompactSensorBox(
                            icon: "humidity.fill",
                            label: "Humid",
                            value: String(format: "%.0f", snapshot.humidity),
                            unit: "%",
                            color: .teal
                        )

                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
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

// MARK: - Compact Sensor Box (for grid layout)
struct CompactSensorBox: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 9, weight: .medium))
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
                    .font(.system(size: 13))
                Text("Home Assistant")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // Main content grid
            VStack(spacing: 16) {
                // Temperature - Large feature
                HStack(spacing: 18) {
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
                                .font(.system(size: 18))
                                .foregroundStyle(temperatureColor)
                            Text(String(format: "%.0f", snapshot.outsideTemperature))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(temperatureColor)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Outside Temperature")
                            .font(.system(size: 14, weight: .semibold))

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", snapshot.outsideTemperature))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(temperatureColor)
                            Text("°F")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }

                        // High/Low temps
                        if snapshot.temperatureMax > 0 || snapshot.temperatureMin > 0 {
                            HStack(spacing: 10) {
                                if snapshot.temperatureMax > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text(String(format: "%.0f°", snapshot.temperatureMax))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(.orange.opacity(0.8))
                                }

                                if snapshot.temperatureMin > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text(String(format: "%.0f°", snapshot.temperatureMin))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(.cyan.opacity(0.8))
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                //Wind & Air Quality Row
                HStack(spacing: 8) {
                    LargeSensorCard(
                        icon: "wind",
                        label: !snapshot.windDirection.isEmpty ? "Wind (\(snapshot.windDirection))" : "Wind",
                        value: String(format: "%.1f", snapshot.windSpeed),
                        unit: "mph",
                        detail: nil,
                        color: windColor
                    )

                    if snapshot.windSpeedMax > 0 {
                        LargeSensorCard(
                            icon: "wind.circle",
                            label: "Max Gust",
                            value: String(format: "%.1f", snapshot.windSpeedMax),
                            unit: "mph",
                            detail: nil,
                            color: windColor.opacity(0.7)
                        )
                    }

                    LargeSensorCard(
                        icon: "aqi.medium",
                        label: "AQI",
                        value: String(format: "%.0f", snapshot.aqi),
                        unit: "",
                        detail: nil,
                        color: aqiColor
                    )
                }
                .padding(.horizontal, 16)

                // Rain & Environmental Row
                HStack(spacing: 8) {
                    LargeSensorCard(
                        icon: "drop.fill",
                        label: "Rain",
                        value: String(format: "%.1f", snapshot.rainAmount),
                        unit: "mm",
                        detail: nil,
                        color: .blue
                    )

                    LargeSensorCard(
                        icon: "circle.hexagongrid",
                        label: "PM2.5",
                        value: String(format: "%.0f", snapshot.pm25),
                        unit: "µg/m³",
                        detail: nil,
                        color: pm25Color
                    )

                    if snapshot.humidity > 0 {
                        LargeSensorCard(
                            icon: "humidity.fill",
                            label: "Humid",
                            value: String(format: "%.0f", snapshot.humidity),
                            unit: "%",
                            detail: nil,
                            color: .teal
                        )
                    }

                    if snapshot.lightLevel > 0 {
                        LargeSensorCard(
                            icon: "sun.max.fill",
                            label: "Light",
                            value: formatWithThousandsSeparator(snapshot.lightLevel),
                            unit: "lux",
                            detail: nil,
                            color: .yellow
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 14)
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
        VStack(alignment: .leading, spacing: 2) {
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
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
    }
}

// MARK: - Large Sensor Card (for readable large widget)
struct LargeSensorCard: View {
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
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            if let detail = detail {
                Text(detail)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 5)
        .padding(.vertical, 6)
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
        .containerBackground(for: .widget) {
            Color.clear
        }
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
