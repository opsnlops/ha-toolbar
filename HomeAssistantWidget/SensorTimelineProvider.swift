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

    private let storage = SharedSensorStorage.shared

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
                lastUpdated: Date()
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
        let snapshot = await fetchLiveData() ?? storage.getSensorSnapshot()
        return SensorTimelineEntry(
            date: Date(),
            snapshot: snapshot,
            configuration: configuration
        )
    }

    func timeline(for configuration: SensorConfigurationIntent, in context: Context) async -> Timeline<SensorTimelineEntry> {
        let currentDate = Date()

        // Fetch live data from Home Assistant
        let snapshot = await fetchLiveData() ?? storage.getSensorSnapshot()

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
        guard storage.hasConfiguration(),
              let hostname = storage.getServerHostname(),
              let authToken = storage.getAuthToken(),
              let tempEntity = storage.getTemperatureEntity(),
              let windEntity = storage.getWindSpeedEntity(),
              let rainEntity = storage.getRainAmountEntity() else {
            return nil
        }

        let client = HomeAssistantAPIClient(
            hostname: hostname,
            port: storage.getServerPort(),
            useTLS: storage.getServerUseTLS(),
            authToken: authToken
        )

        do {
            // Fetch all entity IDs from storage for consistency
            let snapshot = try await client.fetchSensorData(
                temperatureEntity: tempEntity,
                windSpeedEntity: windEntity,
                rainAmountEntity: rainEntity,
                temperatureMaxEntity: storage.getTemperatureMaxEntity(),
                temperatureMinEntity: storage.getTemperatureMinEntity(),
                humidityEntity: storage.getHumidityEntity(),
                windSpeedMaxEntity: storage.getWindSpeedMaxEntity(),
                pm25Entity: storage.getPM25Entity(),
                lightLevelEntity: storage.getLightLevelEntity(),
                aqiEntity: storage.getAQIEntity(),
                windDirectionEntity: storage.getWindDirectionEntity()
            )

            // Save to shared storage so app can see widget is working
            storage.saveOutsideTemperature(snapshot.outsideTemperature)
            storage.saveWindSpeed(snapshot.windSpeed)
            storage.saveRainAmount(snapshot.rainAmount)
            storage.saveTemperatureMax(snapshot.temperatureMax)
            storage.saveTemperatureMin(snapshot.temperatureMin)
            storage.saveHumidity(snapshot.humidity)
            storage.saveWindSpeedMax(snapshot.windSpeedMax)
            storage.savePM25(snapshot.pm25)
            storage.saveLightLevel(snapshot.lightLevel)
            storage.saveAQI(snapshot.aqi)
            storage.saveWindDirection(snapshot.windDirection)

            return snapshot
        } catch {
            // If fetch fails, fall back to cached data
            return nil
        }
    }
}
