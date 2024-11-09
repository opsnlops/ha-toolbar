
import OSLog
import SimpleKeychain
import SwiftUI

struct ContentView: View {

    var client: WebSocketClient?

    @State var serverHostname: String = ""
    @State var authToken: String = ""

    @ObservedObject var sensors = MonitoredSensors.shared

    let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "ContentView")

    let simpleKeychain = SimpleKeychain(service: "io.opsnlops.HomeAssistantToolbar", synchronizable: true)

    init() {
        logger.debug("Getting our configuration from the keychain")

        // Go see if there's an auth token in the keychain already
        if let token = try? simpleKeychain.string(forKey: "authToken") {
            _authToken = State(initialValue: token)
        }

        if let extHostname = try? simpleKeychain.string(forKey: "externalHostname") {
            _serverHostname = State(initialValue: extHostname)
        }



    }


    var body: some View {
        VStack {

            Button("Connect") {
                connect()
            }

            Text("Total events: \(sensors.totalEventsProcessed)")
            Text("Temperature: \(sensors.outsideTemperature, specifier: "%.1f")°F")
            Text("Rain Amount: \(sensors.rainAmount, specifier: "%.2f")mm")
            Text("Wind Speed: \(sensors.windSpeed, specifier: "%.1f") MPH")
        }
        .padding()
    }

    func connect() {
        let client = WebSocketClient(hostname: serverHostname, authToken: authToken)
        client.connect()
    }
}

#Preview {
    ContentView()
}
