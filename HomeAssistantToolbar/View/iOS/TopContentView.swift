import OSLog
import SwiftUI

struct TopContentView: View {


    @State var navigationPath = NavigationPath()

    var body: some View {

        NavigationSplitView {
            List {
                Section("Things to Click") {

                    NavigationLink {
                        EntitiesView()
                    } label: {
                        Label("View Sensors", systemImage: "sensor")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }

                }
            }
            .navigationTitle("HA Toolbar")
        }
        detail: {
            NavigationStack(path: $navigationPath) {
                #if os(tvOS)
                EntitiesView()
                #endif


            }

        }
    }
}
