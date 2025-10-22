//
//  CestovniVykazWidgetLiveActivity.swift
//  CestovniVykazWidget
//
//  Created by Jakub Sedláček on 16.09.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CestovniVykazWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CestovniVykazWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CestovniVykazWidgetAttributes.self) { context in
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

extension CestovniVykazWidgetAttributes {
    fileprivate static var preview: CestovniVykazWidgetAttributes {
        CestovniVykazWidgetAttributes(name: "World")
    }
}

extension CestovniVykazWidgetAttributes.ContentState {
    fileprivate static var smiley: CestovniVykazWidgetAttributes.ContentState {
        CestovniVykazWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CestovniVykazWidgetAttributes.ContentState {
         CestovniVykazWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CestovniVykazWidgetAttributes.preview) {
   CestovniVykazWidgetLiveActivity()
} contentStates: {
    CestovniVykazWidgetAttributes.ContentState.smiley
    CestovniVykazWidgetAttributes.ContentState.starEyes
}
