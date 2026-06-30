import SwiftUI
import SwiftData

struct AddWorkoutRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    let date: Date
    var onRecordCreated: ((WorkoutRecord) -> Void)? = nil
    @State private var searchText = ""

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var groupedExercises: [(BodyPart, [Exercise])] {
        let dict = Dictionary(grouping: filteredExercises, by: { $0.bodyPart })
        return BodyPart.allCases.compactMap { part in
            if let items = dict[part], !items.isEmpty {
                return (part, items)
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        String(localized: "add.noExercises"),
                        systemImage: "dumbbell",
                        description: Text(String(localized: "add.noExercisesDescription"))
                    )
                    .listRowBackground(Color.clear)
                } else if filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(groupedExercises, id: \.0) { part, items in
                        Section(header: Text(part.displayName)) {
                            ForEach(items) { exercise in
                                Button {
                                    addRecord(for: exercise)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(exercise.name)
                                                .font(.body)
                                                .foregroundStyle(.primary)
                                            Text(exercise.type.displayName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: String(localized: "common.search", defaultValue: "운동 검색"))
            .navigationTitle(String(localized: "add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private func addRecord(for exercise: Exercise) {
        let record = WorkoutRecord(date: date, exercise: exercise)
        modelContext.insert(record)
        // Add one initial set
        let firstSet = SetRecord(order: 1, workoutRecord: record)
        modelContext.insert(firstSet)
        dismiss()
        onRecordCreated?(record)
    }
}

