import WidgetKit
import SwiftUI
import AppIntents

struct SensorTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: SensorSnapshot
    let configuration: SensorConfigurationIntent
}

struct SensorTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = SensorTimelineEntry
    typealias Intent = SensorConfigurationIntent

    func placeholder(in context: Context) -> SensorTimelineEntry {
        SensorTimelineEntry(
            date: Date(),
            snapshot: SensorSnapshot(
                outsideTemperature: 72.5,
                windSpeed: 5.2,
                rainAmount: 0.0,
                temperatureMax: 78.0,
                temperatureMin: 65.0,
                humidity: 60.0,
                windSpeedMax: 12.0,
                pm25: 8.0,
                lightLevel: 450.0,
                aqi: 42.0,
                windDirection: "NW",
                pressure: 1013.5,
                lastUpdated: Date(),
                temperatureTrend: .stable,
                windSpeedTrend: .stable,
                humidityTrend: .stable,
                pm25Trend: .stable,
                lightLevelTrend: .stable,
                pressureTrend: .stable
            ),
            configuration: SensorConfigurationIntent()
        )
    }

    func snapshot(for configuration: SensorConfigurationIntent, in context: Context) async -> SensorTimelineEntry {
        // For widget gallery preview, use placeholder data
        if context.isPreview {
            return placeholder(in: context)
        }

        // Try to fetch live data
        let snapshot = await fetchLiveData() ?? SharedSensorStorage.getSensorSnapshot()
        return SensorTimelineEntry(
            date: Date(),
            snapshot: snapshot,
            configuration: configuration
        )
    }

    func timeline(for configuration: SensorConfigurationIntent, in context: Context) async -> Timeline<SensorTimelineEntry> {
        let currentDate = Date()

        // Fetch live data from Home Assistant
        let snapshot = await fetchLiveData() ?? SharedSensorStorage.getSensorSnapshot()

        let entry = SensorTimelineEntry(
            date: currentDate,
            snapshot: snapshot,
            configuration: configuration
        )

        // Refresh timeline in 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    /// Fetch live data directly from Home Assistant API
    private func fetchLiveData() async -> SensorSnapshot? {
        // Check if we have configuration and fetch all entity IDs from storage
        guard SharedSensorStorage.hasConfiguration(),
              let hostname = SharedSensorStorage.getServerHostname(),
              let authToken = SharedSensorStorage.getAuthToken(),
              let tempEntity = SharedSensorStorage.getTemperatureEntity(),
              let windEntity = SharedSensorStorage.getWindSpeedEntity(),
              let rainEntity = SharedSensorStorage.getRainAmountEntity() else {
            return nil
        }

        let client = HomeAssistantAPIClient(
            hostname: hostname,
            port: SharedSensorStorage.getServerPort(),
            useTLS: SharedSensorStorage.getServerUseTLS(),
            authToken: authToken
        )

        do {
            // Fetch all entity IDs from storage for consistency
            let snapshot = try await client.fetchSensorData(
                temperatureEntity: tempEntity,
                windSpeedEntity: windEntity,
                rainAmountEntity: rainEntity,
                temperatureMaxEntity: SharedSensorStorage.getTemperatureMaxEntity(),
                temperatureMinEntity: SharedSensorStorage.getTemperatureMinEntity(),
                humidityEntity: SharedSensorStorage.getHumidityEntity(),
                windSpeedMaxEntity: SharedSensorStorage.getWindSpeedMaxEntity(),
                pm25Entity: SharedSensorStorage.getPM25Entity(),
                lightLevelEntity: SharedSensorStorage.getLightLevelEntity(),
                aqiEntity: SharedSensorStorage.getAQIEntity(),
                windDirectionEntity: SharedSensorStorage.getWindDirectionEntity(),
                pressureEntity: SharedSensorStorage.getPressureEntity()
            )

            // Save to shared storage so app can see widget is working
            SharedSensorStorage.saveOutsideTemperature(snapshot.outsideTemperature)
            SharedSensorStorage.saveWindSpeed(snapshot.windSpeed)
            SharedSensorStorage.saveRainAmount(snapshot.rainAmount)
            SharedSensorStorage.saveTemperatureMax(snapshot.temperatureMax)
            SharedSensorStorage.saveTemperatureMin(snapshot.temperatureMin)
            SharedSensorStorage.saveHumidity(snapshot.humidity)
            SharedSensorStorage.saveWindSpeedMax(snapshot.windSpeedMax)
            SharedSensorStorage.savePM25(snapshot.pm25)
            SharedSensorStorage.saveLightLevel(snapshot.lightLevel)
            SharedSensorStorage.saveAQI(snapshot.aqi)
            SharedSensorStorage.saveWindDirection(snapshot.windDirection)
            SharedSensorStorage.savePressure(snapshot.pressure)

            return snapshot
        } catch {
            // If fetch fails, fall back to cached data
            return nil
        }
    }
}
