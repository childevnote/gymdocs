import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [WorkoutRecord]
    @State private var selectedDate: Date = Date()
    @State private var recordToNavigate: WorkoutRecord?
    @State private var showAddSheet = false

    private var recordsForSelectedDate: [WorkoutRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        return allRecords.filter { calendar.startOfDay(for: $0.date) == startOfDay }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StreakBannerView(allRecords: allRecords)
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
                            NavigationLink(destination: WorkoutDetailView(record: record)) {
                                WorkoutRecordRow(record: record)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                modelContext.delete(recordsForSelectedDate[index])
                            }
                        }
                    }
                } header: {
                    Text(String(localized: "home.workouts"))
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
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddWorkoutRecordView(date: selectedDate) { newRecord in
                    recordToNavigate = newRecord
                }
            }
            .navigationDestination(item: $recordToNavigate) { record in
                WorkoutDetailView(record: record)
            }
        }
    }
}

struct WorkoutRecordRow: View {
    let record: WorkoutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.exercise?.name ?? "")
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
