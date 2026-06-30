import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [WorkoutRecord]
    @Query private var dailySummaries: [DailySummary]
    @State private var selectedDate: Date = Date()
    @State private var recordToNavigate: WorkoutRecord?
    @State private var showAddSheet = false

    private var recordsForSelectedDate: [WorkoutRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        return allRecords.filter { calendar.startOfDay(for: $0.date) == startOfDay }
    }

    private var currentSummary: DailySummary? {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        return dailySummaries.first(where: { $0.date == startOfDay })
    }

    private var isFinished: Bool {
        currentSummary?.isFinished == true
    }

    private var hasAtLeastOneCompletedSet: Bool {
        recordsForSelectedDate.contains(where: { record in
            record.sets.contains(where: { $0.isCompleted })
        })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StreakBannerView(dailySummaries: dailySummaries)
                }

                Section {
                    DatePicker(
                        String(localized: "home.date"),
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }

                Section {
                    if recordsForSelectedDate.isEmpty {
                        ContentUnavailableView(
                            String(localized: "home.noRecords"),
                            systemImage: "tray",
                            description: Text(String(localized: "home.noRecordsDescription"))
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(recordsForSelectedDate) { record in
                            NavigationLink(destination: WorkoutDetailView(record: record, isLocked: isFinished)) {
                                WorkoutRecordRow(record: record)
                            }
                        }
                        .onDelete { indexSet in
                            if isFinished { return }
                            for index in indexSet {
                                modelContext.delete(recordsForSelectedDate[index])
                            }
                        }
                    }
                } header: {
                    Text(String(localized: "home.workouts"))
                }

                if !recordsForSelectedDate.isEmpty {
                    Section {
                        if isFinished {
                            Button {
                                currentSummary?.isFinished = false
                            } label: {
                                Label("수정 잠금 해제", systemImage: "lock.open.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .tint(.orange)
                        } else {
                            Button {
                                if let summary = currentSummary {
                                    summary.isFinished = true
                                } else {
                                    let newSummary = DailySummary(date: selectedDate, isFinished: true)
                                    modelContext.insert(newSummary)
                                }
                            } label: {
                                Label("오늘 운동 완료 🏁", systemImage: "flag.checkered")
                                    .frame(maxWidth: .infinity)
                                    .font(.headline)
                            }
                            .tint(.teal)
                            .buttonStyle(.borderedProminent)
                            .disabled(!hasAtLeastOneCompletedSet)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
            }
            .navigationTitle(String(localized: "home.title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(isFinished)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddWorkoutRecordView(date: selectedDate) { newRecord in
                    recordToNavigate = newRecord
                }
            }
            .navigationDestination(item: $recordToNavigate) { record in
                WorkoutDetailView(record: record, isLocked: isFinished)
            }
        }
    }
}

struct WorkoutRecordRow: View {
    let record: WorkoutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.exercise?.localizedName ?? "")
                .font(.headline)
            HStack {
                Text("\(record.sets.count) " + String(localized: "home.sets"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if record.totalVolume > 0 {
                    Text("·")
                        .foregroundStyle(.secondary)
                    if record.exercise?.type == .weightAndReps {
                        Text(String(format: "%.0f kg", record.totalVolume))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(formatDuration(Int(record.totalVolume)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

func formatDuration(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    if m > 0 {
        return String(format: "%dm %ds", m, s)
    }
    return String(format: "%ds", s)
}
