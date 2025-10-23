import SimpleKeychain
import SwiftUI

struct NetworkSettings: View {
    @AppStorage("serverPort") private var serverPort: Int = 443
    @AppStorage("serverUseTLS") private var serverUseTLS: Bool = true

    @State private var authToken: String = ""
    @State private var externalHostname: String = ""

    let simpleKeychain = SimpleKeychain(service: "io.opsnlops.HomeAssistantToolbar", synchronizable: true)
    private let service = HomeAssistantService.shared


    init() {

        // Go see if there's an auth token in the keychain already
        if let token = try? simpleKeychain.string(forKey: "authToken") {
            _authToken = State(initialValue: token)
        }

        if let extHostname = try? simpleKeychain.string(forKey: "externalHostname") {
            _externalHostname = State(initialValue: extHostname)
        }

    }



    var body: some View {
        VStack {
            Form {

                Section(header: Text("Server Connection")) {
                    TextField("External Hostname", text: $externalHostname)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #else
                        .disableAutocorrection(true)
                        #endif
                        .onChange(of: externalHostname) {
                            saveExternalHostname()
                            updateServiceConfiguration()
                        }
                    TextField("Port", value: $serverPort, format: .number)
                        .onChange(of: serverPort) { _ in updateServiceConfiguration() }
                    Toggle("Use TLS", isOn: $serverUseTLS)
                        .onChange(of: serverUseTLS) { _ in updateServiceConfiguration() }
                }

                Section(header: Text("Authentication")) {
                    SecureField("Auth Token", text: $authToken)
                        .onChange(of: authToken) {
                            saveAuthToken()
                            updateServiceConfiguration()
                        }
                }
            }
            Spacer()
        }
    }

    private func saveAuthToken() {
        do {
            try simpleKeychain.set(authToken, forKey: "authToken")
            print("Auth token saved to keychain.")
        } catch {
            print("Failed to save auth token to keychain:", error)
        }
    }

    private func saveExternalHostname() {
        do {
            try simpleKeychain.set(externalHostname, forKey: "externalHostname")
            print("External hostname: \(externalHostname) saved to keychain.")
        } catch {
            print("Failed to save external hostname to keychain:", error)
        }
    }

    private func updateServiceConfiguration() {
        service.configure(hostname: externalHostname, authToken: authToken)
        SharedSensorStorage.saveConfiguration(
            hostname: externalHostname,
            port: serverPort,
            useTLS: serverUseTLS,
            authToken: authToken,
            temperatureEntity: UserDefaults.standard.string(forKey: "outsideTemperatureEntity") ?? "",
            windSpeedEntity: UserDefaults.standard.string(forKey: "windSpeedEntity") ?? "",
            rainAmountEntity: UserDefaults.standard.string(forKey: "rainAmountEntity") ?? "",
            temperatureMaxEntity: UserDefaults.standard.string(forKey: "temperatureMaxEntity") ?? "",
            temperatureMinEntity: UserDefaults.standard.string(forKey: "temperatureMinEntity") ?? "",
            humidityEntity: UserDefaults.standard.string(forKey: "humidityEntity") ?? "",
            windSpeedMaxEntity: UserDefaults.standard.string(forKey: "windSpeedMaxEntity") ?? "",
            pm25Entity: UserDefaults.standard.string(forKey: "pm25Entity") ?? "",
            lightLevelEntity: UserDefaults.standard.string(forKey: "lightLevelEntity") ?? "",
            aqiEntity: UserDefaults.standard.string(forKey: "aqiEntity") ?? "",
            windDirectionEntity: UserDefaults.standard.string(forKey: "windDirectionEntity") ?? "",
            pressureEntity: UserDefaults.standard.string(forKey: "pressureEntity") ?? ""
        )
    }
}

#Preview {
    NetworkSettings()
}
