//
//  DepoTimerWidgetLiveActivity.swift
//  DepoTimerWidget
//
//  Created by Tim Statler on 5/15/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DepoTimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DepoTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DepoTimerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension DepoTimerWidgetAttributes {
    fileprivate static var preview: DepoTimerWidgetAttributes {
        DepoTimerWidgetAttributes(name: "World")
    }
}

extension DepoTimerWidgetAttributes.ContentState {
    fileprivate static var smiley: DepoTimerWidgetAttributes.ContentState {
        DepoTimerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DepoTimerWidgetAttributes.ContentState {
         DepoTimerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DepoTimerWidgetAttributes.preview) {
   DepoTimerWidgetLiveActivity()
} contentStates: {
    DepoTimerWidgetAttributes.ContentState.smiley
    DepoTimerWidgetAttributes.ContentState.starEyes
}
