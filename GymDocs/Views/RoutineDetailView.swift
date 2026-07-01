import SwiftUI
import SwiftData
import UIKit

struct RoutineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var dailySummaries: [DailySummary]
    let routine: Routine
    @State private var showExercisePicker = false
    @State private var showLimitAlert = false
    @State private var exerciseToReplace: RoutineExercise?
    
    // Workflow States
    @State private var isWorkoutActive = false
    @State private var isWorkoutCompleted = false
    @State private var completedSets: Set<UUID> = []

    var sortedExercises: [RoutineExercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            if routine.exercises.isEmpty {
                ContentUnavailableView(
                    String(localized: "routines.noExercises", defaultValue: "등록된 운동이 없습니다"),
                    systemImage: "dumbbell",
                    description: Text(String(localized: "routines.addExercisesPrompt", defaultValue: "운동 추가 버튼을 눌러 운동을 추가하세요."))
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(sortedExercises) { rExercise in
                    RoutineExerciseSection(
                        rExercise: rExercise,
                        routine: routine,
                        isWorkoutActive: isWorkoutActive,
                        isWorkoutCompleted: isWorkoutCompleted,
                        completedSets: $completedSets,
                        onReplace: {
                            exerciseToReplace = rExercise
                            showExercisePicker = true
                        }
                    )
                }
            }
            
            if !isWorkoutCompleted {
                Section {
                    Button {
                        if routine.exercises.count >= 20 {
                            showLimitAlert = true
                        } else {
                            exerciseToReplace = nil
                            showExercisePicker = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(String(localized: "routines.addExerciseTitle", defaultValue: "운동 추가"))
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                    .tint(.blue)
                }
            }
        }
        .navigationTitle(routine.name)
        .toolbar {
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
            if let target = exerciseToReplace {
                RoutineSingleExercisePickerView(routine: routine, targetToReplace: target)
            } else {
                RoutineExercisePickerView(routine: routine)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !routine.exercises.isEmpty {
                if !isWorkoutActive && !isWorkoutCompleted {
                    // SETUP MODE
                    Button {
                        withAnimation {
                            isWorkoutActive = true
                        }
                    } label: {
                        Text(String(localized: "routines.startWorkout", defaultValue: "이 루틴으로 운동 시작"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.blue)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                } else if isWorkoutActive && !isWorkoutCompleted {
                    // ACTIVE WORKOUT MODE
                    Button {
                        finishWorkout()
                    } label: {
                        Text(String(localized: "routines.finishWorkout", defaultValue: "이 루틴 운동 완료 🏁"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "FFD52E"))
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                } else {
                    // COMPLETED MODE
                    Button {
                        dismiss()
                        NotificationCenter.default.post(name: .switchToHomeTab, object: nil)
                    } label: {
                        Text("운동 종료됨 (홈으로 돌아가기)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
        .alert(String(localized: "routines.limitTitle", defaultValue: "운동 개수 제한"), isPresented: $showLimitAlert) {
            Button(String(localized: "common.ok", defaultValue: "확인"), role: .cancel) { }
        } message: {
            Text(String(localized: "routines.exerciseLimitMessage", defaultValue: "한 루틴당 최대 20개의 운동만 추가할 수 있습니다."))
        }
    }

    private func finishWorkout() {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        
        // Find or create DailySummary
        let summary = dailySummaries.first(where: { $0.date == startOfDay })
        if let existing = summary {
            existing.isFinished = true
        } else {
            let newSummary = DailySummary(date: today, isFinished: true)
            modelContext.insert(newSummary)
        }
        
        _ = RestTimerManager.shared.stop()
        
        for rExercise in sortedExercises {
            guard let exercise = rExercise.exercise else { continue }
            
            // Only save exercises that have at least one completed set
            let exerciseCompletedSets = rExercise.sets.filter { completedSets.contains($0.id) }
            if exerciseCompletedSets.isEmpty { continue }
            
            let record = WorkoutRecord(date: today, exercise: exercise)
            record.originRoutineID = routine.id
            modelContext.insert(record)
            
            let sortedSets = exerciseCompletedSets.sorted { $0.order < $1.order }
            for (index, rSet) in sortedSets.enumerated() {
                let setRecord = SetRecord(order: index + 1, workoutRecord: record)
                setRecord.weight = rSet.weight
                setRecord.reps = rSet.reps
                setRecord.timeDuration = rSet.timeDuration
                setRecord.rangeOfMotion = rSet.rangeOfMotion
                setRecord.restTimeAfterSet = rSet.restTimeAfterSet
                setRecord.isCompleted = true
                modelContext.insert(setRecord)
            }
        }
        
        withAnimation {
            isWorkoutActive = false
            isWorkoutCompleted = true
        }
    }
}

struct RoutineExerciseSection: View {
    @Environment(\.modelContext) private var modelContext
    let rExercise: RoutineExercise
    let routine: Routine
    let isWorkoutActive: Bool
    let isWorkoutCompleted: Bool
    @Binding var completedSets: Set<UUID>
    let onReplace: () -> Void
    
    var sortedSets: [RoutineSet] {
        rExercise.sets.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(rExercise.exercise?.localizedName ?? String(localized: "common.unknown", defaultValue: "알 수 없는 운동"))
                        .font(.title3).bold()
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if !isWorkoutCompleted {
                        Menu {
                            Button {
                                onReplace()
                            } label: {
                                Label(String(localized: "common.change", defaultValue: "변경"), systemImage: "arrow.2.squarepath")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(rExercise)
                                reorderExercises()
                            } label: {
                                Label(String(localized: "common.delete", defaultValue: "삭제"), systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title3)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if !isWorkoutCompleted {
                    HStack(spacing: 12) {
                        Button {
                            if let lastSet = sortedSets.last {
                                modelContext.delete(lastSet)
                                reorderSets()
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.title3)
                        }
                        .disabled(sortedSets.isEmpty)
                        
                        Text(String(localized: "common.set", defaultValue: "세트"))
                            .font(.subheadline).bold()
                        
                        Button {
                            let newOrder = rExercise.sets.count + 1
                            let newSet = RoutineSet(order: newOrder)
                            if let lastSet = sortedSets.last {
                                newSet.weight = lastSet.weight
                                newSet.reps = lastSet.reps
                                newSet.timeDuration = lastSet.timeDuration
                                newSet.rangeOfMotion = lastSet.rangeOfMotion
                            }
                            newSet.routineExercise = rExercise
                            modelContext.insert(newSet)
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
            
            // Sets
            VStack(spacing: 12) {
                ForEach(sortedSets) { rSet in
                    RoutineSetRow(
                        rSet: rSet,
                        type: rExercise.type,
                        isWorkoutActive: isWorkoutActive,
                        isWorkoutCompleted: isWorkoutCompleted,
                        completedSets: $completedSets,
                        onDelete: {
                            modelContext.delete(rSet)
                            reorderSets()
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !isWorkoutCompleted {
                            Button(role: .destructive) {
                                modelContext.delete(rSet)
                                reorderSets()
                            } label: {
                                Label(String(localized: "common.delete", defaultValue: "삭제"), systemImage: "trash")
                            }
                        }
                    }
                }
            }
            

        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }
    
    private func reorderSets() {
        let items = rExercise.sets.sorted { $0.order < $1.order }
        for (i, set) in items.enumerated() {
            set.order = i + 1
        }
    }
    
    private func reorderExercises() {
        let items = routine.exercises.sorted { $0.order < $1.order }
        for (i, ex) in items.enumerated() {
            ex.order = i
        }
    }
}

struct RoutineSetRow: View {
    @Bindable var rSet: RoutineSet
    let type: ExerciseType
    let isWorkoutActive: Bool
    let isWorkoutCompleted: Bool
    @Binding var completedSets: Set<UUID>
    let onDelete: () -> Void
    
    var timerManager = RestTimerManager.shared

    private var isCompleted: Bool {
        completedSets.contains(rSet.id)
    }

    private var isTimerActiveForThis: Bool {
        timerManager.isRunning && timerManager.activeSetId == rSet.id
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if isWorkoutActive || isWorkoutCompleted {
                    // Checkmark in workout mode
                    Button {
                        toggleCompletion()
                    } label: {
                        Text("\(rSet.order)")
                            .font(.subheadline).bold()
                            .foregroundStyle(isCompleted ? Color(hex: "1C1C1E") : .secondary)
                            .frame(width: 32, height: 32)
                            .background(isCompleted ? Color(hex: "FFD52E") : Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isWorkoutCompleted)
                    .sensoryFeedback(.success, trigger: isCompleted)
                } else {
                    // Just the number in setup mode
                    Text("\(rSet.order)")
                        .font(.subheadline).bold()
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if type == .weightAndReps || type == .assistedWeightAndReps {
                    HStack(spacing: 2) {
                        TextField("0", value: $rSet.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3).bold()
                            .frame(width: 60)
                            .disabled(isWorkoutCompleted)
                        Text("kg")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        TextField("0", value: $rSet.reps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3).bold()
                            .frame(width: 60)
                            .disabled(isWorkoutCompleted)
                        Text("회")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if type == .repsOnly {
                    Spacer()
                    HStack(spacing: 2) {
                        TextField("0", value: $rSet.reps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3).bold()
                            .frame(width: 60)
                            .disabled(isWorkoutCompleted)
                        Text("회")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Spacer()
                    HStack(spacing: 2) {
                        TextField("0", value: $rSet.timeDuration, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3).bold()
                            .frame(width: 60)
                            .disabled(isWorkoutCompleted)
                        Text("초")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !isWorkoutCompleted {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 8)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            
            // Timer and ROM (Only visible during active workout)
            if isWorkoutActive && !isWorkoutCompleted {
                HStack {
                    // Rest timer
                    Button {
                        timerManager.toggle(for: rSet.id) { elapsed in
                            rSet.restTimeAfterSet = elapsed
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isTimerActiveForThis ? "stop.fill" : "timer")
                                .font(.caption)
                            if isTimerActiveForThis {
                                Text(formatDuration(timerManager.elapsedSeconds))
                                    .font(.caption)
                                    .monospacedDigit()
                            } else if rSet.restTimeAfterSet > 0 {
                                Text(String(localized: "detail.rest", defaultValue: "휴식") + ": " + formatDuration(rSet.restTimeAfterSet))
                                    .font(.caption)
                            } else {
                                Text(String(localized: "detail.startRest", defaultValue: "휴식 시작"))
                                    .font(.caption)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(isTimerActiveForThis ? .red : .secondary)
                    .sensoryFeedback(.impact(flexibility: .solid), trigger: isTimerActiveForThis)

                    Spacer()

                    // ROM Radio pills
                    if type != .timeOnly {
                        HStack(spacing: 6) {
                            ForEach(RangeOfMotion.allCases, id: \.self) { rom in
                                Button {
                                    rSet.rangeOfMotion = rom
                                } label: {
                                    Text(rom.displayName)
                                        .font(.system(size: 11, weight: rSet.rangeOfMotion == rom ? .bold : .regular))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(rSet.rangeOfMotion == rom ? Color(hex: "FFD52E") : Color.secondary.opacity(0.1))
                                        .foregroundStyle(rSet.rangeOfMotion == rom ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func toggleCompletion() {
        if isCompleted {
            completedSets.remove(rSet.id)
            if isTimerActiveForThis {
                let elapsed = timerManager.stop()
                rSet.restTimeAfterSet = elapsed
            }
        } else {
            completedSets.insert(rSet.id)
            if !isTimerActiveForThis {
                timerManager.start(for: rSet.id)
            }
        }
    }
}

// Format duration helper (Since we removed the global one earlier, we add it back here privately or keep it if it's already in WorkoutDetailView. Wait, WorkoutDetailView has it internally? Let's check. Ah, it was internal to WorkoutDetailView! So we can use it here.)
// But wait, if WorkoutDetailView's formatDuration is private or internal to that file, we can't use it.

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
                                    replaceExercise(with: exercise)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.localizedName)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        Text(exercise.type.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
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
                    Button(String(localized: "common.cancel", defaultValue: "취소")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func replaceExercise(with newExercise: Exercise) {
        targetToReplace.exercise = newExercise
        targetToReplace.type = newExercise.type
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
            
            // Add one default set
            let defaultSet = RoutineSet(order: 1)
            defaultSet.routineExercise = newRoutineEx
            modelContext.insert(defaultSet)
            
            currentOrder += 1
        }
    }
}