import SwiftUI
import SwiftData
import Charts

struct ChartEntry: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let series: String
}

struct ExerciseChartView: View {
    let exercise: Exercise

    private var chartData: [ChartEntry] {
        let sorted = exercise.records.sorted { $0.date < $1.date }
        var entries: [ChartEntry] = []
        for record in sorted {
            entries.append(ChartEntry(date: record.date, value: record.totalVolume, series: String(localized: "chart.volume", defaultValue: "Volume")))
            entries.append(ChartEntry(date: record.date, value: record.intensityScore, series: String(localized: "chart.intensity", defaultValue: "Intensity")))
        }
        return entries
    }

    private var sortedRecordsDesc: [WorkoutRecord] {
        exercise.records.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                if exercise.records.isEmpty {
                    ContentUnavailableView(
                        String(localized: "chart.noData"),
                        systemImage: "chart.xyaxis.line",
                        description: Text(String(localized: "chart.noDataDescription"))
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Chart(chartData) { item in
                        LineMark(
                            x: .value(String(localized: "chart.date"), item.date, unit: .day),
                            y: .value(String(localized: "chart.value"), item.value)
                        )
                        .foregroundStyle(by: .value("Series", item.series))
                        .symbol(by: .value("Series", item.series))
                    }
                    .chartForegroundStyleScale([
                        String(localized: "chart.volume", defaultValue: "Volume"): .blue,
                        String(localized: "chart.intensity", defaultValue: "Intensity"): .orange
                    ])
                    .frame(height: 220)
                    .padding(.vertical, 8)
                }
            } header: {
                Text(String(localized: "chart.progressiveOverload"))
            }

            Section {
                ForEach(sortedRecordsDesc) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.date, style: .date)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        let completedSets = record.sortedSets.filter { $0.isCompleted }
                        if !completedSets.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(completedSets) { set in
                                    if exercise.type == .weightAndReps || exercise.type == .assistedWeightAndReps {
                                        Text("\(set.order). \(String(format: "%.0f", set.weight)) × \(set.reps)")
                                            .font(.footnote)
                                    } else if exercise.type == .repsOnly {
                                        Text("\(set.order). \(set.reps) reps")
                                            .font(.footnote)
                                    } else {
                                        Text("\(set.order). \(formatDuration(set.timeDuration))")
                                            .font(.footnote)
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                        
                        HStack(spacing: 12) {
                            if exercise.type == .timeOnly {
                                Text(String(localized: "detail.totalTime", defaultValue: "Total Time") + ": \(formatDuration(Int(record.totalVolume)))")
                            } else {
                                Text(String(localized: "detail.totalVolume", defaultValue: "Volume") + ": \(String(format: "%.0f", record.totalVolume)) KG")
                            }
                            Text(String(localized: "detail.totalIntensity", defaultValue: "Intensity") + ": \(String(format: "%.0f", record.intensityScore)) SR")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(String(localized: "chart.history"))
            }
        }
        .navigationTitle(exercise.localizedName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
