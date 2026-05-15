import WidgetKit
import SwiftUI

@main
struct DepoTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        DepoControl()
        DepoTimerLiveActivity()
    }
}
