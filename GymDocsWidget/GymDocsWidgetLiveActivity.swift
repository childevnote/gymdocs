//
//  GymDocsWidgetLiveActivity.swift
//  GymDocsWidget
//
//  Created by 김동진 on 7/2/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GymDocsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GymDocsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymDocsWidgetAttributes.self) { context in
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

extension GymDocsWidgetAttributes {
    fileprivate static var preview: GymDocsWidgetAttributes {
        GymDocsWidgetAttributes(name: "World")
    }
}

extension GymDocsWidgetAttributes.ContentState {
    fileprivate static var smiley: GymDocsWidgetAttributes.ContentState {
        GymDocsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GymDocsWidgetAttributes.ContentState {
         GymDocsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GymDocsWidgetAttributes.preview) {
   GymDocsWidgetLiveActivity()
} contentStates: {
    GymDocsWidgetAttributes.ContentState.smiley
    GymDocsWidgetAttributes.ContentState.starEyes
}
