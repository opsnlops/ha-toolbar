import SimpleKeychain
import SwiftUI

struct NetworkSettings: View {
    @AppStorage("serverPort") private var serverPort: Int = 443
    @AppStorage("serverUseTLS") private var serverUseTLS: Bool = true

    @State private var authToken: String = ""
    @State private var externalHostname: String = ""

    let simpleKeychain = SimpleKeychain(service: "io.opsnlops.HomeAssistantToolbar", synchronizable: true)


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
                        .onChange(of: externalHostname) {
                            saveExternalHostname()
                        }
                    TextField("Port", value: $serverPort, format: .number)
                    Toggle("Use TLS", isOn: $serverUseTLS)
                }

                Section(header: Text("Authentication")) {
                    SecureField("Auth Token", text: $authToken)
                        .onChange(of: authToken) {
                            saveAuthToken()
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
}

#Preview {
    NetworkSettings()
}

