import SwiftUI
import SwiftData

struct AddWorkoutRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    let date: Date

    var body: some View {
        List {
            if exercises.isEmpty {
                ContentUnavailableView(
                    String(localized: "add.noExercises"),
                    systemImage: "dumbbell",
                    description: Text(String(localized: "add.noExercisesDescription"))
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(exercises) { exercise in
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
                } header: {
                    Text(String(localized: "add.selectExercise"))
                }
            }
        }
        .navigationTitle(String(localized: "add.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addRecord(for exercise: Exercise) {
        let record = WorkoutRecord(date: date, exercise: exercise)
        modelContext.insert(record)
        // Add one initial set
        let firstSet = SetRecord(order: 1, workoutRecord: record)
        modelContext.insert(firstSet)
        dismiss()
    }
}
