import SwiftUI
import SwiftData
import UIKit

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
                // Removed start workout button from here

                ForEach(sortedExercises) { rExercise in
                    RoutineExerciseRow(rExercise: rExercise)
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
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                } label: {
                    Image(systemName: "checkmark")
                        .bold()
                }
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            RoutineExercisePickerView(routine: routine)
        }
        .safeAreaInset(edge: .bottom) {
            if !routine.exercises.isEmpty {
                Button { startWorkoutFromRoutine() } label: {
                    Text(String(localized: "routines.startWorkout", defaultValue: "이 루틴으로 운동 시작"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "FFD52E"))
                .clipShape(Capsule())
                .padding(.horizontal)
                .padding(.bottom, 8)
                .sensoryFeedback(.success, trigger: showStartedAlert)
            }
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
            firstSet.weight = rExercise.defaultWeight
            firstSet.reps = rExercise.defaultReps
            firstSet.timeDuration = rExercise.defaultTimeDuration
            firstSet.rangeOfMotion = rExercise.defaultRangeOfMotion
            modelContext.insert(firstSet)
        }
        showStartedAlert = true
    }
}

struct RoutineExerciseRow: View {
    @Bindable var rExercise: RoutineExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(rExercise.exercise?.localizedName ?? String(localized: "common.unknown", defaultValue: "알 수 없는 운동"))
                .font(.headline)

            if rExercise.type != .timeOnly {
                HStack(spacing: 6) {
                    ForEach(RangeOfMotion.allCases, id: \.self) { rom in
                        Button {
                            rExercise.defaultRangeOfMotion = rom
                        } label: {
                            Text(rom.displayName)
                                .font(.system(size: 11, weight: rExercise.defaultRangeOfMotion == rom ? .bold : .regular))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(rExercise.defaultRangeOfMotion == rom ? Color(hex: "FFD52E") : Color.secondary.opacity(0.1))
                                .foregroundStyle(rExercise.defaultRangeOfMotion == rom ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if rExercise.type == .weightAndReps || rExercise.type == .assistedWeightAndReps {
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text(rExercise.type == .assistedWeightAndReps ? String(localized: "detail.assistWeight", defaultValue: "보조무게") : String(localized: "detail.weight", defaultValue: "무게"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $rExercise.defaultWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    VStack(alignment: .leading) {
                        Text(String(localized: "detail.reps", defaultValue: "횟수"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $rExercise.defaultReps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            } else if rExercise.type == .repsOnly {
                VStack(alignment: .leading) {
                    Text(String(localized: "detail.reps", defaultValue: "횟수"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $rExercise.defaultReps, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            } else {
                VStack(alignment: .leading) {
                    Text(String(localized: "detail.duration", defaultValue: "시간"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $rExercise.defaultTimeDuration, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    Text(String(localized: "detail.seconds", defaultValue: "초"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 8)
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
                                    }
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

