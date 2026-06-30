import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let routine: Routine
    @State private var showExercisePicker = false
    @State private var showLimitAlert = false
    @State private var showStartedAlert = false

    var sortedExercises: [RoutineExercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            if routine.exercises.isEmpty {
                ContentUnavailableView(
                    String(localized: "routines.noExercises", defaultValue: "등록된 운동이 없습니다"),
                    systemImage: "dumbbell",
                    description: Text(String(localized: "routines.addExercisesPrompt", defaultValue: "+ 버튼을 눌러 운동을 추가하세요."))
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    Button {
                        startWorkoutFromRoutine()
                    } label: {
                        Label(String(localized: "routines.startWorkout", defaultValue: "이 루틴으로 운동 시작"), systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    }
                    .tint(.teal)
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .sensoryFeedback(.success, trigger: showStartedAlert)
                }

                ForEach(sortedExercises) { rExercise in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rExercise.exercise?.localizedName ?? String(localized: "common.unknown", defaultValue: "알 수 없는 운동"))
                            .font(.body)
                        Text(rExercise.type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { indexSet in
                    let items = sortedExercises
                    for index in indexSet {
                        modelContext.delete(items[index])
                    }
                    let updated = routine.exercises.sorted { $0.order < $1.order }
                    for (i, ex) in updated.enumerated() {
                        ex.order = i
                    }
                }
                .onMove { source, destination in
                    var items = sortedExercises
                    items.move(fromOffsets: source, toOffset: destination)
                    for (i, ex) in items.enumerated() {
                        ex.order = i
                    }
                }
            }
        }
        .navigationTitle(routine.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if routine.exercises.count >= 20 {
                        showLimitAlert = true
                    } else {
                        showExercisePicker = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            if !routine.exercises.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            RoutineExercisePickerView(routine: routine)
        }
        .alert(String(localized: "routines.limitTitle", defaultValue: "운동 개수 제한"), isPresented: $showLimitAlert) {
            Button(String(localized: "common.ok", defaultValue: "확인"), role: .cancel) { }
        } message: {
            Text(String(localized: "routines.exerciseLimitMessage", defaultValue: "한 루틴당 최대 20개의 운동만 추가할 수 있습니다."))
        }
        .alert(String(localized: "routines.workoutStarted", defaultValue: "운동 시작!"), isPresented: $showStartedAlert) {
            Button(String(localized: "common.ok", defaultValue: "확인")) {
                NotificationCenter.default.post(name: .switchToHomeTab, object: nil)
            }
        } message: {
            Text(String(localized: "routines.workoutStartedMessage", defaultValue: "오늘의 운동이 홈 화면에 등록되었습니다."))
        }
    }

    private func startWorkoutFromRoutine() {
        let today = Date()
        for rExercise in sortedExercises {
            guard let exercise = rExercise.exercise else { continue }
            let record = WorkoutRecord(date: today, exercise: exercise)
            modelContext.insert(record)
            let firstSet = SetRecord(order: 1, workoutRecord: record)
            modelContext.insert(firstSet)
        }
        showStartedAlert = true
    }
}

struct RoutineExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    let routine: Routine
    
    @State private var selectedExercises: Set<UUID> = []
    @State private var searchText = ""

    private var remainingSlots: Int {
        max(0, 20 - routine.exercises.count)
    }

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return allExercises }
        return allExercises.filter { $0.localizedName.localizedCaseInsensitiveContains(searchText) }
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
                if filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(groupedExercises, id: \.0) { part, items in
                        Section(header: Text(part.displayName)) {
                            ForEach(items) { exercise in
                                Button {
                                    toggleSelection(exercise)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.localizedName)
                                                .font(.body)
                                                .foregroundStyle(.primary)
                                            Text(exercise.type.displayName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedExercises.contains(exercise.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.blue)
                                        } else {
                                            Image(systemName: "circle")
                                }
                                .buttonStyle(.plain)
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
                    Button(String(localized: "common.cancel", defaultValue: "취소")) {
                        dismiss()
                    }
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
        } else {
            if selectedExercises.count < remainingSlots {
                selectedExercises.insert(exercise.id)
            }
        }
    }

    private func addSelectedExercises() {
        var currentOrder = routine.exercises.count
        for exercise in allExercises where selectedExercises.contains(exercise.id) {
            let newRoutineEx = RoutineExercise(order: currentOrder, type: exercise.type, exercise: exercise)
            routine.exercises.append(newRoutineEx)
            currentOrder += 1
        }
    }
}

