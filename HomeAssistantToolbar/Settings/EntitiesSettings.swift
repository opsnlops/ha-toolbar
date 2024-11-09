
import SimpleKeychain
import SwiftUI

struct EntitiesSettings: View {
    @AppStorage("outsideTemperatureEntity") private var outsideTemperatureEntity: String = ""
    @AppStorage("windSpeedEntity") private var windSpeedEntity: String = ""
    @AppStorage("rainAmountEntity") private var rainAmountEntity: String = ""


    var body: some View {
        VStack {
            Form {

                Section(header: Text("Home Assistant Entities")) {
                    TextField("Outside Temperature", text: $outsideTemperatureEntity)
                    TextField("Wind Speed", text: $windSpeedEntity)
                    TextField("Rain Amount", text: $rainAmountEntity)
                }

            }
            Spacer()
        }
    }

}

#Preview {
    EntitiesSettings()
}

