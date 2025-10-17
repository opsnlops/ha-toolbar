
import SimpleKeychain
import SwiftUI

struct EntitiesSettings: View {
    @AppStorage("outsideTemperatureEntity") private var outsideTemperatureEntity: String = ""
    @AppStorage("windSpeedEntity") private var windSpeedEntity: String = ""
    @AppStorage("rainAmountEntity") private var rainAmountEntity: String = ""
    @AppStorage("temperatureMaxEntity") private var temperatureMaxEntity: String = ""
    @AppStorage("temperatureMinEntity") private var temperatureMinEntity: String = ""
    @AppStorage("humidityEntity") private var humidityEntity: String = ""
    @AppStorage("windSpeedMaxEntity") private var windSpeedMaxEntity: String = ""
    @AppStorage("pm25Entity") private var pm25Entity: String = ""
    @AppStorage("lightLevelEntity") private var lightLevelEntity: String = ""
    @AppStorage("aqiEntity") private var aqiEntity: String = ""
    @AppStorage("windDirectionEntity") private var windDirectionEntity: String = ""
    @AppStorage("pressureEntity") private var pressureEntity: String = ""

    var body: some View {
        Form {
            Section {
                TextField("Outside Temperature", text: $outsideTemperatureEntity, prompt: Text("sensor.outside_temperature"))
                TextField("Wind Speed", text: $windSpeedEntity, prompt: Text("sensor.wind_speed_avg"))
                TextField("Rain Amount", text: $rainAmountEntity, prompt: Text("sensor.rain_today_mm"))
            } header: {
                Text("Required Sensors")
            } footer: {
                Text("These sensors are required for the widget to function.")
            }

            Section {
                TextField("24-Hour Temperature Max", text: $temperatureMaxEntity, prompt: Text("sensor.outside_temperature_24_hour_max"))
                TextField("24-Hour Temperature Min", text: $temperatureMinEntity, prompt: Text("sensor.outside_temperature_24_hour_min"))
                TextField("Outside Humidity", text: $humidityEntity, prompt: Text("sensor.outside_humidity"))
            } header: {
                Text("Optional Sensors - Temperature & Humidity")
            } footer: {
                Text("These sensors provide additional temperature and humidity data.")
            }

            Section {
                TextField("24-Hour Wind Speed Max", text: $windSpeedMaxEntity, prompt: Text("sensor.outside_wind_speed_24_hour_max"))
                TextField("Wind Direction", text: $windDirectionEntity, prompt: Text("sensor.wind_direction"))
            } header: {
                Text("Optional Sensors - Wind")
            } footer: {
                Text("Additional wind-related sensors for detailed weather information.")
            }

            Section {
                TextField("PM 2.5 Particles", text: $pm25Entity, prompt: Text("sensor.outside_pm_2_5um"))
                TextField("AirNow AQI", text: $aqiEntity, prompt: Text("sensor.airnow_aqi"))
                TextField("Light Level (Lux)", text: $lightLevelEntity, prompt: Text("sensor.outside_light_level"))
                TextField("Barometric Pressure", text: $pressureEntity, prompt: Text("sensor.office_pressure"))
            } header: {
                Text("Optional Sensors - Air Quality & Environment")
            } footer: {
                Text("Air quality, ambient light, and barometric pressure measurements.")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    EntitiesSettings()
}

