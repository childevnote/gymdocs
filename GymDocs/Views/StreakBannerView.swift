import SwiftUI
import SwiftData

struct StreakBannerView: View {
    let dailySummaries: [DailySummary]

    private var weeklyStreak: Int {
        calculateWeeklyStreak(from: dailySummaries)
    }

    var body: some View {
        if weeklyStreak > 0 {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(weeklyStreak)" + String(localized: "streak.weeks"))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(String(localized: "streak.keepGoing"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("🔥")
                    .font(.largeTitle)
            }
            .padding(.vertical, 4)
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "streak.noStreak"))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(String(localized: "streak.startNow"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("💪")
                    .font(.largeTitle)
            }
            .padding(.vertical, 4)
        }
    }
}

/// Calculates the number of consecutive weeks (ending with the current week) that have at least one finished workout.
func calculateWeeklyStreak(from summaries: [DailySummary]) -> Int {
    let finishedSummaries = summaries.filter { $0.isFinished }
    guard !finishedSummaries.isEmpty else { return 0 }

    let calendar = Calendar.current
    let today = Date()

    // Get unique weeks that have finished records (using year + weekOfYear)
    var weeksWithRecords = Set<DateComponents>()
    for summary in finishedSummaries {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: summary.date)
        weeksWithRecords.insert(components)
    }

    // Check current week first
    let currentWeek = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
    guard weeksWithRecords.contains(currentWeek) else { return 0 }

    // Count consecutive weeks going backwards
    var streak = 1
    var checkDate = today

    while true {
        guard let previousWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: checkDate) else { break }
        let prevWeek = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: previousWeekDate)

        if weeksWithRecords.contains(prevWeek) {
            streak += 1
            checkDate = previousWeekDate
        } else {
            break
        }
    }

    return streak
}
