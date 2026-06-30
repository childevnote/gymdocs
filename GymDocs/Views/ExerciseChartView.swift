import SwiftUI
import SwiftData
import Charts

struct ExerciseChartView: View {
    let exercise: Exercise

    private var chartData: [(date: Date, volume: Double)] {
        exercise.records
            .sorted { $0.date < $1.date }
            .map { (date: $0.date, volume: $0.intensityScore) }
    }

    var body: some View {
        List {
            Section {
                if chartData.isEmpty {
                    ContentUnavailableView(
                        String(localized: "chart.noData"),
                        systemImage: "chart.bar",
                        description: Text(String(localized: "chart.noDataDescription"))
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Chart(chartData, id: \.date) { item in
                        BarMark(
                            x: .value(String(localized: "chart.date"), item.date, unit: .day),
                            y: .value(String(localized: "chart.intensity"), item.volume)
                        )
                        .foregroundStyle(.blue.gradient)
                        .cornerRadius(4)
                    }
                    .chartYAxisLabel(exercise.type == .assistedWeightAndReps ? "kg" : String(localized: "chart.score"))
                    .frame(height: 220)
                    .padding(.vertical, 8)
                }
            } header: {
                Text(String(localized: "chart.progressiveOverload"))
            }

            Section {
                ForEach(chartData, id: \.date) { item in
                    HStack {
                        Text(item.date, style: .date)
                            .font(.subheadline)
                        Spacer()
                        if exercise.type == .weightAndReps || exercise.type == .assistedWeightAndReps {
                            Text(String(format: "%.0f", item.volume))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if exercise.type == .repsOnly {
                            Text(String(format: "%.0f", item.volume))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(formatDuration(Int(item.volume)))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text(String(localized: "chart.history"))
            }
        }
        .navigationTitle(exercise.localizedName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
