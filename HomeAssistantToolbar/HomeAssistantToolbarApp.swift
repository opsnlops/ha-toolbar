#if os(macOS)
import AppKit
#endif

import Foundation
import OSLog
import SimpleKeychain
import SwiftUI

func formatLightLevel(_ value: Double) -> String {
    if value >= 1000 {
        let thousands = value / 1000.0
        return String(format: "%.1fk", thousands)
    } else {
        return String(format: "%.0f", value)
    }
}

@main
struct HomeAssistantToolbarApp: App {

    #if os(macOS)
    class SettingsWindowController: NSWindowController {
        static var shared: SettingsWindowController = {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.setContentSize(NSSize(width: 400, height: 300))
            window.title = "Preferences"
            window.styleMask = [.titled, .closable, .miniaturizable]
            let controller = SettingsWindowController(window: window)
            return controller
        }()

        func showWindow() {
            self.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    #endif  


    let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "ContentView")

    let simpleKeychain = SimpleKeychain(service: "io.opsnlops.HomeAssistantToolbar", synchronizable: true)

    let client = WebSocketClient.shared
    let sharedStorage = SharedSensorStorage.shared

    @ObservedObject var sensors = MonitoredSensors.shared
    @State private var isSettingsWindowOpen = false

    @State var serverHostname: String = ""
    @State var authToken: String = ""

    @AppStorage("serverPort") private var serverPort: Int = 443
    @AppStorage("serverUseTLS") private var serverUseTLS: Bool = true
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

    init()
    {
        let defaultPreferences: [String: Any] = [
            "serverPort": 443,
            "serverUseTLS": true,
            "outsideTemperatureEntity": "sensor.outside_temperature",
            "windSpeedEntity": "sensor.wind_speed_avg",
            "rainAmountEntity": "sensor.rain_today_mm",
            "temperatureMaxEntity": "sensor.outside_temperature_24_hour_max",
            "temperatureMinEntity": "sensor.outside_temperature_24_hour_min",
            "humidityEntity": "sensor.outside_humidity",
            "windSpeedMaxEntity": "sensor.outside_wind_speed_24_hour_max",
            "pm25Entity": "sensor.outside_pm_2_5um",
            "lightLevelEntity": "sensor.outside_light_level",
            "aqiEntity": "sensor.airnow_aqi",
            "windDirectionEntity": "sensor.wind_direction"
        ]
        UserDefaults.standard.register(defaults: defaultPreferences)


        logger.debug("Getting our configuration from the keychain")

        // Go see if there's an auth token in the keychain already
        if let token = try? simpleKeychain.string(forKey: "authToken") {
            _authToken = State(initialValue: token)
        }

        if let extHostname = try? simpleKeychain.string(forKey: "externalHostname") {
            _serverHostname = State(initialValue: extHostname)
            logger.debug("setting external hostname to \(extHostname)")
        }

        client.configure(hostname: serverHostname, authToken: authToken)

        // Save configuration to shared storage for widget access
        if !serverHostname.isEmpty && !authToken.isEmpty {
            sharedStorage.saveConfiguration(
                hostname: serverHostname,
                port: serverPort,
                useTLS: serverUseTLS,
                authToken: authToken,
                temperatureEntity: outsideTemperatureEntity,
                windSpeedEntity: windSpeedEntity,
                rainAmountEntity: rainAmountEntity,
                temperatureMaxEntity: temperatureMaxEntity,
                temperatureMinEntity: temperatureMinEntity,
                humidityEntity: humidityEntity,
                windSpeedMaxEntity: windSpeedMaxEntity,
                pm25Entity: pm25Entity,
                lightLevelEntity: lightLevelEntity,
                aqiEntity: aqiEntity,
                windDirectionEntity: windDirectionEntity
            )
            self.connect()
        }
    }

    func connect() {

        let connectResult = client.connect()
        switch (connectResult) {
            case .success:
                logger.debug("Connected to \(serverHostname)")
            case .failure(let error):
                logger.fault("Failed to connect to \(serverHostname): \(error)")
        }
    }


    var body: some Scene {

        #if os(iOS) || os(tvOS)
        WindowGroup {
            TopContentView()
        }
        #endif

#if os(macOS)


        MenuBarExtra {

            // Drop down menu when clicked
            VStack(alignment: .leading, spacing: 12) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Temperature")
                        .font(.headline)
                    Text("🌡️ Current: \(sensors.outsideTemperature, specifier: "%.1f")°F")
                    Text("📈 24h Max: \(sensors.temperatureMax, specifier: "%.1f")°F")
                    Text("📉 24h Min: \(sensors.temperatureMin, specifier: "%.1f")°F")
                    Text("💧 Humidity: \(sensors.humidity, specifier: "%.0f")%")
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Wind")
                        .font(.headline)
                    Text("💨 Current: \(sensors.windSpeed, specifier: "%.1f") mph")
                    Text("🧭 Direction: \(sensors.windDirection)")
                    Text("🌪️ 24h Max: \(sensors.windSpeedMax, specifier: "%.1f") mph")
                }

                Divider()

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rain")
                            .font(.headline)
                        Text("🌧️ \(sensors.rainAmount, specifier: "%.2f") mm")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Light")
                            .font(.headline)
                        Text("☀️ \(formatLightLevel(sensors.lightLevel)) lux")
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Air Quality")
                        .font(.headline)
                    Text("🏭 AQI: \(sensors.aqi, specifier: "%.0f")")
                    Text("🔬 PM2.5: \(sensors.pm25, specifier: "%.0f") µg/m³")
                }

                Divider()

                HStack {
                    Button(action: {
                            SettingsWindowController.shared.showWindow()  // Show the settings window
                        }
                    ) { Image(systemName: "gearshape") }
                    .buttonStyle(BorderlessButtonStyle())

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("💻")
                            Text("Events: \(sensors.totalEventsProcessed)")
                        }
                        .font(.caption)

                        HStack(spacing: 4) {
                            Text("🔌")
                            Text(client.isConnected ? "Connected" : "Disconnected")
                        }
                        .font(.caption)

                        HStack(spacing: 4) {
                            Text("📡")
                            Text("Pings: \(client.totalPings)")
                        }
                        .font(.caption)
                    }

                    Spacer()

                    Button( action: {
                        NSApplication.shared.terminate(nil)
                    })
                    { Image(systemName: "xmark") }
                    .buttonStyle(BorderlessButtonStyle())
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
