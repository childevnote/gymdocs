import SwiftUI
import SwiftData

struct RoutineSingleExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    let routine: Routine
    let targetToReplace: RoutineExercise
    @State private var searchText = ""
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return allExercises }
        return allExercises.filter { $0.localizedName.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var groupedExercises: [(BodyPart, [Exercise])] {
        let dict = Dictionary(grouping: filteredExercises, by: { $0.bodyPart })
        return BodyPart.allCases.compactMap { part in
            if let items = dict[part], !items.isEmpty { return (part, items) }
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText).listRowBackground(Color.clear)
                } else {
                    ForEach(groupedExercises, id: \.0) { part, items in
                        Section(header: Text(part.displayName)) {
                            ForEach(items) { exercise in
                                Button {
                                    targetToReplace.exercise = exercise
                                    targetToReplace.type = exercise.type
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.localizedName).font(.body).foregroundStyle(.primary)
                                        if !exercise.localizedDesc.isEmpty {
                                            Text(exercise.localizedDesc).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                        Text(exercise.type.displayName).font(.caption).foregroundStyle(.tertiary)
                                    }
                                }
                                .buttonStyle(.hapticPress)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: String(localized: "common.search", defaultValue: "운동 검색"))
            .navigationTitle(String(localized: "routines.changeExerciseTitle", defaultValue: "운동 변경"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "취소")) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Exercise Picker (다중 추가)

struct RoutineExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    let routine: Routine
    
    @State private var selectedExercises: Set<UUID> = []
    @State private var searchText = ""
    
    private var remainingSlots: Int { max(0, 20 - routine.exercises.count) }
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return allExercises }
        return allExercises.filter { $0.localizedName.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var groupedExercises: [(BodyPart, [Exercise])] {
        let dict = Dictionary(grouping: filteredExercises, by: { $0.bodyPart })
        return BodyPart.allCases.compactMap { part in
            if let items = dict[part], !items.isEmpty { return (part, items) }
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText).listRowBackground(Color.clear)
                } else {
                    ForEach(groupedExercises, id: \.0) { part, items in
                        Section(header: Text(part.displayName)) {
                            ForEach(items) { exercise in
                                Button {
                                    toggleSelection(exercise)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.localizedName).font(.body).foregroundStyle(.primary)
                                            if !exercise.localizedDesc.isEmpty {
                                                Text(exercise.localizedDesc).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                            }
                                            Text(exercise.type.displayName).font(.caption).foregroundStyle(.tertiary)
                                        }
                                        Spacer()
                                        if selectedExercises.contains(exercise.id) {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                                        } else {
                                            Image(systemName: "circle")
                                        }
                                    }
                                }
                                .buttonStyle(.hapticPress)
                            }
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: selectedExercises.count)
            .searchable(text: $searchText, prompt: String(localized: "common.search", defaultValue: "운동 검색"))
            .navigationTitle(String(localized: "routines.addExerciseTitle", defaultValue: "운동 추가"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "취소")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.add", defaultValue: "추가") + " (\(selectedExercises.count))") {
                        addSelectedExercises()
                        dismiss()
                    }
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
    }
    
    private func toggleSelection(_ exercise: Exercise) {
        if selectedExercises.contains(exercise.id) {
            selectedExercises.remove(exercise.id)
        } else if selectedExercises.count < remainingSlots {
            selectedExercises.insert(exercise.id)
        }
    }
    
    private func addSelectedExercises() {
        var currentOrder = routine.exercises.count
        for exercise in allExercises where selectedExercises.contains(exercise.id) {
            let newRoutineEx = RoutineExercise(order: currentOrder, type: exercise.type, exercise: exercise)
            routine.exercises.append(newRoutineEx)
            let defaultSet = RoutineSet(order: 1)
            defaultSet.routineExercise = newRoutineEx
            modelContext.insert(defaultSet)
            currentOrder += 1
        }
    }
}
