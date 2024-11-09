import Foundation
import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case network, homeAssistantEntities
    }
    var body: some View {
        TabView {
            NetworkSettings()
                .tabItem {
                    Label("Network", systemImage: "network")
                }
                .tag(Tabs.network)

            EntitiesSettings()
                .tabItem {
                    Label("Home Assistant Entities", systemImage: "house")
                }
                .tag(Tabs.homeAssistantEntities)
        }
        .padding(20)
#if os(macOS)
        .frame(width: 600, height: 400)
#endif
    }
}

#Preview {
    SettingsView()
}
