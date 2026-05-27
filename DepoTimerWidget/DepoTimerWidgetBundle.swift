//
//  DepoTimerWidgetBundle.swift
//  DepoTimerWidget
//
//  Created by Tim Statler on 5/15/26.
//

import WidgetKit
import SwiftUI

@main
struct DepoTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        DepoTimerWidget()
        DepoTimerWidgetControl()
        DepoTimerWidgetLiveActivity()
    }
}
