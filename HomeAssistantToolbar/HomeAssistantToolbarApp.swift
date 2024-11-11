#if os(macOS)
import AppKit
#endif

import Foundation
import OSLog
import SimpleKeychain
import SwiftUI

@main
struct HomeAssistantToolbarApp: App {

    @Environment(\.scenePhase) var scenePhase

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

    @ObservedObject var sensors = MonitoredSensors.shared
    @State private var isSettingsWindowOpen = false

    @State var serverHostname: String = ""
    @State var authToken: String = ""

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

    #if os(macOS)
        // Connect if we can
        self.connect()
    #endif
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
        .onChange(of: scenePhase, initial: false) { old, phase in
            if (phase == .active && !authToken.isEmpty && !serverHostname.isEmpty) {
                logger.debug("Scene is active, connecting to \(serverHostname)")
                connect()
            }
            else if (phase == .background || phase == .inactive) {
                logger.info("Scene is inactive, disconnecting from \(serverHostname)")
                client.disconnect()
            }
        }
        #endif

#if os(macOS)


        MenuBarExtra {

            // Drop down menu when clicked
            VStack {
                Text("🌡️ Outside Temperature: \(sensors.outsideTemperature, specifier: "%.1f")°F")
                Text("💨 Wind Speed: \(sensors.windSpeed, specifier: "%.0f") mph")
                Text("🌧️ Rain Amount: \(sensors.rainAmount, specifier: "%.2f") mm")
                Divider()


                HStack {
                    Button(action: {
                            SettingsWindowController.shared.showWindow()  // Show the settings window
                        }
                    ) { Image(systemName: "gearshape") }
                    .buttonStyle(BorderlessButtonStyle())

                    Spacer()
                    Text("💻 Events Processed: \(sensors.totalEventsProcessed)")
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
