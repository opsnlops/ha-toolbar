
import OSLog
import SimpleKeychain
import SwiftUI

struct EntitiesView: View {

    var client: WebSocketClient?

    @State var serverHostname: String = ""
    @State var authToken: String = ""

    @ObservedObject var sensors = MonitoredSensors.shared

    let logger = Logger(subsystem: "io.opsnlops.HomeAssistantToolbar", category: "ContentView")


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
    EntitiesView()
}
