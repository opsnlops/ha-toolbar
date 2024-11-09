

import SwiftUI

@main
struct HomeAssistantToolbarApp: App {

    @ObservedObject var sensors = MonitoredSensors.shared
    @State private var isSettingsWindowOpen = false

    init()
    {
        let defaultPreferences: [String: Any] = [
            "serverPort": 443,
            "serverUseTLS": true,
            "outsideTemperatureEntity": "sensor.outside_temperature",
            "windSpeedEntity": "sensor.wind_speed_avg",
            "rainAmountEntity": "sensor.rain_today_mm"
        ]
        UserDefaults.standard.register(defaults: defaultPreferences)
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
        }

#if os(macOS)

        Settings {
            SettingsView()
        }

        MenuBarExtra {

            // Drop down menu when clicked
            VStack {
                Text("🌡️ Outside Temperature: \(sensors.outsideTemperature, specifier: "%.1f")°F")
                Text("💨 Wind Speed: \(sensors.windSpeed, specifier: "%.1f") mph")
                Text("🌧️ Rain Amount: \(sensors.rainAmount, specifier: "%.1f") mm")
                Divider()
                Text("💻 Events Processed: \(sensors.totalEventsProcessed)")
                Divider()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
        } label: {
            // Text shown in the menu bar
            Text("\(sensors.outsideTemperature, specifier: "%.1f")°F")
                .frame(width: 40)
        }
        .menuBarExtraStyle(.window)
#endif
    }
}
