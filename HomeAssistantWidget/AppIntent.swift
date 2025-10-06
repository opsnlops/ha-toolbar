//
//  AppIntent.swift
//  HomeAssistantWidget
//
//  Created by April White on 10/5/25.
//

import AppIntents
import WidgetKit

struct SensorConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Sensor Configuration"
    static var description = IntentDescription("Configure which sensors to display in the widget.")

    @Parameter(title: "Display Style", default: .all)
    var displayStyle: DisplayStyleOption?
}

enum DisplayStyleOption: String, AppEnum {
    case all = "All Sensors"
    case temperatureOnly = "Temperature Only"
    case temperatureAndWind = "Temperature & Wind"
    case temperatureAndRain = "Temperature & Rain"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Display Style"
    }

    static var caseDisplayRepresentations: [DisplayStyleOption: DisplayRepresentation] {
        [
            .all: "All Sensors",
            .temperatureOnly: "Temperature Only",
            .temperatureAndWind: "Temperature & Wind",
            .temperatureAndRain: "Temperature & Rain"
        ]
    }
}
