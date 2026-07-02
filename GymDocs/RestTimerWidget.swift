import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - 중요 안내
// 이 파일은 다이내믹 아일랜드(Live Activities) 위젯 UI를 정의합니다.
// Xcode에서 다음 설정을 반드시 진행해야 위젯이 정상 작동합니다.
// 1. File > New > Target 에서 'Widget Extension'을 추가하세요 (Include Live Activity 체크).
// 2. 추가된 위젯 타겟에 이 `RestTimerWidget.swift` 파일과 `RestTimerAttributes.swift` 파일이 포함되도록 Target Membership을 체크하세요.
// 3. 메인 앱 타겟의 Info.plist에 `NSSupportsLiveActivities` 키를 추가하고 값을 `YES`로 설정하세요.

@main
struct GymDocsWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestTimerWidget()
    }
}

struct RestTimerWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // 잠금화면 및 알림 배너 UI
            VStack {
                Text("휴식 시간")
                    .font(.headline)
                Text(timerInterval: context.state.startDate...Date.distantFuture)
                    .font(.title.bold())
                    .foregroundColor(.blue)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // 다이내믹 아일랜드가 확장되었을 때의 UI
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Text("휴식 중")
                            .font(.headline)
                        Text(timerInterval: context.state.startDate...Date.distantFuture)
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
                    .frame(maxWidth: 40)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
            }
        }
    }
}
