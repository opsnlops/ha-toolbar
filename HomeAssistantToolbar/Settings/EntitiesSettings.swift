
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

    var body: some View {
        Form {
            Section {
                LabeledTextField(
                    label: "Outside Temperature",
                    placeholder: "sensor.outside_temperature",
                    text: $outsideTemperatureEntity
                )

                LabeledTextField(
                    label: "Wind Speed",
                    placeholder: "sensor.wind_speed_avg",
                    text: $windSpeedEntity
                )

                LabeledTextField(
                    label: "Rain Amount",
                    placeholder: "sensor.rain_today_mm",
                    text: $rainAmountEntity
                )
            } header: {
                Text("Required Sensors")
            } footer: {
                Text("These sensors are required for the widget to function.")
            }

            Section {
                LabeledTextField(
                    label: "24-Hour Temperature Max",
                    placeholder: "sensor.outside_temperature_24_hour_max",
                    text: $temperatureMaxEntity
                )

                LabeledTextField(
                    label: "24-Hour Temperature Min",
                    placeholder: "sensor.outside_temperature_24_hour_min",
                    text: $temperatureMinEntity
                )

                LabeledTextField(
                    label: "Outside Humidity",
                    placeholder: "sensor.outside_humidity",
                    text: $humidityEntity
                )
            } header: {
                Text("Optional Sensors - Temperature & Humidity")
            } footer: {
                Text("These sensors provide additional temperature and humidity data.")
            }

            Section {
                LabeledTextField(
                    label: "24-Hour Wind Speed Max",
                    placeholder: "sensor.outside_wind_speed_24_hour_max",
                    text: $windSpeedMaxEntity
                )

                LabeledTextField(
                    label: "Wind Direction",
                    placeholder: "sensor.wind_direction",
                    text: $windDirectionEntity
                )
            } header: {
                Text("Optional Sensors - Wind")
            } footer: {
                Text("Additional wind-related sensors for detailed weather information.")
            }

            Section {
                LabeledTextField(
                    label: "PM 2.5 Particles",
                    placeholder: "sensor.outside_pm_2_5um",
                    text: $pm25Entity
                )

                LabeledTextField(
                    label: "AirNow AQI",
                    placeholder: "sensor.airnow_aqi",
                    text: $aqiEntity
                )

                LabeledTextField(
                    label: "Light Level (Lux)",
                    placeholder: "sensor.outside_light_level",
                    text: $lightLevelEntity
                )
            } header: {
                Text("Optional Sensors - Air Quality & Light")
            } footer: {
                Text("Air quality and ambient light measurements.")
            }
        }
    }
}

// MARK: - Labeled Text Field Component
struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
                .foregroundStyle(.primary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EntitiesSettings()
}

