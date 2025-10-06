//
//  HomeAssistantWidget.swift
//  HomeAssistantWidget
//
//  Created by April White on 10/5/25.
//

import WidgetKit
import SwiftUI

struct HomeAssistantWidget: Widget {
    let kind: String = "HomeAssistantWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SensorConfigurationIntent.self,
            provider: SensorTimelineProvider()
        ) { entry in
            HomeAssistantWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Home Assistant Sensors")
        .description("View your Home Assistant sensor data at a glance.")
        .containerBackgroundRemovable(true)
        #if os(macOS)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        #elseif os(iOS)
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        #endif
    }
}

#if os(iOS)
// CarPlay-specific widget
struct HomeAssistantCarPlayWidget: Widget {
    let kind: String = "HomeAssistantCarPlayWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SensorConfigurationIntent.self,
            provider: SensorTimelineProvider()
        ) { entry in
            CarPlayWidgetView(entry: entry)
        }
        .configurationDisplayName("Home Assistant")
        .description("View temperature and weather sensors.")
        .supportedFamilies([.accessoryRectangular])
        .containerBackgroundRemovable(true)
    }
}
#endif
