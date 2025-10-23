import Foundation
import Testing
@testable import HomeAssistantToolbar

struct SharedSensorStorageTests {

    init() {
        SharedSensorStorage.resetForTesting()
    }

    @Test
    func saveAndLoadSnapshotValues() {
        SharedSensorStorage.resetForTesting()
        SharedSensorStorage.saveOutsideTemperature(72.0)
        SharedSensorStorage.saveWindSpeed(5.5)
        SharedSensorStorage.saveRainAmount(1.2)
        SharedSensorStorage.saveTemperatureMax(80)
        SharedSensorStorage.saveTemperatureMin(60)
        SharedSensorStorage.saveHumidity(45)
        SharedSensorStorage.saveWindSpeedMax(12)
        SharedSensorStorage.savePM25(8)
        SharedSensorStorage.saveLightLevel(400)
        SharedSensorStorage.saveAQI(35)
        SharedSensorStorage.saveWindDirection("NE")
        SharedSensorStorage.savePressure(1008)
        SharedSensorStorage.saveTotalEventsProcessed(42)
        SharedSensorStorage.saveTemperatureTrend(.up)
        SharedSensorStorage.saveWindSpeedTrend(.down)
        SharedSensorStorage.saveHumidityTrend(.stable)
        SharedSensorStorage.savePM25Trend(.up)
        SharedSensorStorage.saveLightLevelTrend(.down)
        SharedSensorStorage.savePressureTrend(.stable)

        let snapshot = SharedSensorStorage.getSensorSnapshot()

        #expect(snapshot.outsideTemperature == 72.0)
        #expect(snapshot.windSpeed == 5.5)
        #expect(snapshot.rainAmount == 1.2)
        #expect(snapshot.temperatureMax == 80)
        #expect(snapshot.temperatureMin == 60)
        #expect(snapshot.humidity == 45)
        #expect(snapshot.windSpeedMax == 12)
        #expect(snapshot.pm25 == 8)
        #expect(snapshot.lightLevel == 400)
        #expect(snapshot.aqi == 35)
        #expect(snapshot.windDirection == "NE")
        #expect(snapshot.pressure == 1008)
        #expect(SharedSensorStorage.getTemperatureTrend() == .up)
        #expect(SharedSensorStorage.getWindSpeedTrend() == .down)
        #expect(SharedSensorStorage.getHumidityTrend() == .stable)
        #expect(SharedSensorStorage.getPM25Trend() == .up)
        #expect(SharedSensorStorage.getLightLevelTrend() == .down)
        #expect(SharedSensorStorage.getPressureTrend() == .stable)
    }

    @Test
    func configurationRoundTrip() {
        SharedSensorStorage.resetForTesting()
        SharedSensorStorage.saveConfiguration(
            hostname: "example.local",
            port: 8123,
            useTLS: false,
            authToken: "token",
            temperatureEntity: "sensor.temp",
            windSpeedEntity: "sensor.wind",
            rainAmountEntity: "sensor.rain",
            temperatureMaxEntity: "sensor.temp_max",
            temperatureMinEntity: "sensor.temp_min",
            humidityEntity: "sensor.humidity",
            windSpeedMaxEntity: "sensor.wind_max",
            pm25Entity: "sensor.pm25",
            lightLevelEntity: "sensor.light",
            aqiEntity: "sensor.aqi",
            windDirectionEntity: "sensor.wind_dir",
            pressureEntity: "sensor.pressure"
        )

        #expect(SharedSensorStorage.hasConfiguration())
        #expect(SharedSensorStorage.getServerHostname() == "example.local")
        #expect(SharedSensorStorage.getServerPort() == 8123)
        #expect(SharedSensorStorage.getServerUseTLS() == false)
        #expect(SharedSensorStorage.getAuthToken() == "token")
        #expect(SharedSensorStorage.getTemperatureEntity() == "sensor.temp")
    }
}
