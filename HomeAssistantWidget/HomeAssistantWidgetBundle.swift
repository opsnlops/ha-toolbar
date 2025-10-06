//
//  HomeAssistantWidgetBundle.swift
//  HomeAssistantWidget
//
//  Created by April White on 10/5/25.
//

import WidgetKit
import SwiftUI

@main
struct HomeAssistantWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeAssistantWidget()
        #if os(iOS)
        HomeAssistantCarPlayWidget()
        #endif
    }
}
