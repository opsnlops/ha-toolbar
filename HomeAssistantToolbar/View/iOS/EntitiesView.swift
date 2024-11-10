
import OSLog
import SimpleKeychain
import SwiftUI

struct EntitiesView: View {

    let client = WebSocketClient.shared

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
            Text("Wind Speed: \(sensors.windSpeed, specifier: "%.0f") MPH")
        }
        .padding()
    }

    func connect() {
        _ = client.connect()
    }

}

#Preview {
    EntitiesView()
}
