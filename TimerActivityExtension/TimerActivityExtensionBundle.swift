//
//  TimerActivityExtensionBundle.swift
//  TimerActivityExtension
//
//  Created by Marcello Guida on 14/11/25.
//

import WidgetKit
import SwiftUI

@main
struct TimerActivityExtensionBundle: WidgetBundle {
    var body: some Widget {
        TimerActivityExtension()
        TimerActivityExtensionControl()
        TimerActivityExtensionLiveActivity()
    }
}
