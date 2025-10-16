
import OSLog
import SimpleKeychain
import SwiftUI

func formatLightLeveliOS(_ value: Double) -> String {
    if value >= 1000 {
        let thousands = value / 1000.0
        return String(format: "%.1fk", thousands)
    } else {
        return String(format: "%.0f", value)
    }
}

struct EntitiesView: View {

    @ObservedObject var client = WebSocketClient.shared

    @ObservedObject var sensors = MonitoredSensors.shared

    let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "ContentView")

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                Button("Force Connection") {
                    connect()
                }
                .padding(.bottom)
                .buttonStyle(.borderedProminent)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Temperature")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text("🌡️ Current: \(sensors.outsideTemperature, specifier: "%.1f")°F")
                        Image(systemName: sensors.temperatureTrend.symbolName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(0.6)
                    }
                    Text("📈 24h Max: \(sensors.temperatureMax, specifier: "%.1f")°F")
                    Text("📉 24h Min: \(sensors.temperatureMin, specifier: "%.1f")°F")
                    HStack(spacing: 4) {
                        Text("💧 Humidity: \(sensors.humidity, specifier: "%.0f")%")
                        Image(systemName: sensors.humidityTrend.symbolName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Wind")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text("💨 Current: \(sensors.windSpeed, specifier: "%.1f") mph")
                        Image(systemName: sensors.windSpeedTrend.symbolName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(0.6)
                    }
                    Text("🧭 Direction: \(sensors.windDirection)")
                    Text("🌪️ 24h Max: \(sensors.windSpeedMax, specifier: "%.1f") mph")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Precipitation")
                        .font(.headline)
                    Text("🌧️ Rain: \(sensors.rainAmount, specifier: "%.2f") mm")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Air Quality")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text("🏭 AQI: \(sensors.aqi, specifier: "%.0f")")
                        Image(systemName: sensors.aqiTrend.symbolName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(0.6)
                    }
                    HStack(spacing: 4) {
                        Text("🔬 PM2.5: \(sensors.pm25, specifier: "%.0f") µg/m³")
                        Image(systemName: sensors.pm25Trend.symbolName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Light")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text("☀️ Level: \(formatLightLeveliOS(sensors.lightLevel)) lux")
                        Image(systemName: sensors.lightLevelTrend.symbolName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                Spacer()
                    .frame(height: 20)

                VStack(spacing: 4) {
                    Text("Connection Info")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("💻 Events: \(sensors.totalEventsProcessed)")
                        .font(.caption)
                    Text("🔌 Connected: \(client.isConnected ? "Yes" : "No")")
                        .font(.caption)
                    Text("📡 Pings: \(client.totalPings)")
                        .font(.caption)
                }

            }
            .padding()
        }
        .task {
            await client.loadSensorData()
        }
    }

    func connect() {
        _ = client.connect()
    }

}

#Preview {
    EntitiesView()
}
