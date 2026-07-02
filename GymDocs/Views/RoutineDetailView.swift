import SwiftUI
import SwiftData
import UIKit

// MARK: - ROM Slider View

struct ROMSliderView: View {
    @Binding var value: RangeOfMotion
    let disabled: Bool
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let cases = RangeOfMotion.allCases  // normal, concentric, eccentric, full
    
    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let segmentWidth = totalWidth / CGFloat(cases.count - 1)
            let currentX = CGFloat(value.sliderIndex) * segmentWidth
            let clampedX = isDragging ? dragOffset.clamped(to: 0...totalWidth) : currentX
            
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 6)
                
                // Active track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "FFD52E"))
                    .frame(width: clampedX + 10, height: 6)
                
                // Tick marks + labels
                ForEach(Array(cases.enumerated()), id: \.offset) { index, rom in
                    let x = CGFloat(index) * segmentWidth
                    VStack(spacing: 4) {
                        Circle()
                            .fill(rom == value ? Color(hex: "FFD52E") : Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                        Text(rom.displayName)
                            .font(.system(size: 9, weight: rom == value ? .bold : .regular))
                            .foregroundStyle(rom == value ? .primary : .secondary)
                            .fixedSize()
                    }
                    .offset(x: x - 4, y: -18)
                }
                
                // Thumb
                Circle()
                    .fill(Color(hex: "FFD52E"))
                    .frame(width: 22, height: 22)
                    .shadow(radius: 2)
                    .offset(x: clampedX - 11)
                    .gesture(
                        disabled ? nil : DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                isDragging = true
                                dragOffset = g.location.x.clamped(to: 0...totalWidth)
                            }
                            .onEnded { g in
                                isDragging = false
                                let x = g.location.x.clamped(to: 0...totalWidth)
                                let idx = Int((x / segmentWidth).rounded())
                                    .clamped(to: 0...(cases.count - 1))
                                value = RangeOfMotion.fromSliderIndex(idx)
                            }
                    )
            }
            .frame(height: 6)
            .padding(.top, 28) // room for labels above
        }
        .frame(height: 50)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Main View

struct RoutineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var session = ActiveRoutineSession.shared
    
    let routine: Routine
    @State private var showExercisePicker = false
    @State private var showLimitAlert = false
    @State private var exerciseToReplace: RoutineExercise?
    
    // Workout state
    @State private var completedSets: Set<UUID> = []
    
    // Finish-related
    @State private var showFinishAlert = false
    @State private var showSyncRoutineAlert = false
    
    var timerManager = RestTimerManager.shared
    
    // "다른 루틴이 활성화 중" 경고
    @State private var showOtherActiveAlert = false
    
    var isThisRoutineActive: Bool {
        session.isCurrentRoutine(routine.id)
    }
    
    var isWorkoutActive: Bool {
        isThisRoutineActive
    }

    var sortedExercises: [RoutineExercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }
    
    /// 운동 중 기존 루틴 세트 값과 달라진 게 있는지 체크
    var hasChangesFromOriginal: Bool {
        // 수정 여부를 정교하게 비교하려면 스냅샷이 필요하지만,
        // 단순화: 완료된 세트가 하나라도 있으면 "변경 가능성 있음"으로 간주
        !completedSets.isEmpty
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
                        completedSets: $completedSets,
                        onReplace: {
                            exerciseToReplace = rExercise
                            showExercisePicker = true
                        }
                    )
                }
            }
            
            // 운동 추가 버튼 (비활성 상태에서만)
            if !isWorkoutActive {
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
                    Image(systemName: "checkmark").bold()
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
                if !isWorkoutActive {
                    // 세팅 모드 버튼
                    Button {
                        if session.isActive && !isThisRoutineActive {
                            showOtherActiveAlert = true
                        } else {
                            session.start(routineID: routine.id)
                            completedSets = []
                        }
                    } label: {
                        Text(String(localized: "routines.startWorkout", defaultValue: "이 루틴으로 운동 시작"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.hapticPress)
                    .background(Color.blue)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                } else {
                    VStack(spacing: 8) {
                        if timerManager.isRunning {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("휴식 타이머")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text(formatDuration(timerManager.elapsedSeconds))
                                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                                Button {
                                    if let activeId = timerManager.activeSetId,
                                       let ex = routine.exercises.first(where: { $0.sets.contains(where: { s in s.id == activeId }) }),
                                       let rSet = ex.sets.first(where: { $0.id == activeId }) {
                                        let elapsed = timerManager.stop()
                                        rSet.restTimeAfterSet = elapsed
                                    } else {
                                        _ = timerManager.stop()
                                    }
                                } label: {
                                    Text("휴식 종료")
                                        .font(.headline)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 14)
                                        .background(Color.white)
                                        .foregroundStyle(.black)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.hapticPress)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .padding(.horizontal)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        } else {
                            // 운동 완료 버튼
                            Button { showFinishAlert = true } label: {
                                Text(String(localized: "routines.finishWorkout", defaultValue: "이 루틴 운동 완료 🏁"))
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.hapticPress)
                            .background(Color(hex: "FFD52E"))
                            .clipShape(Capsule())
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .alert(String(localized: "routines.limitTitle", defaultValue: "운동 개수 제한"), isPresented: $showLimitAlert) {
            Button(String(localized: "common.ok", defaultValue: "확인"), role: .cancel) { }
        } message: {
            Text(String(localized: "routines.exerciseLimitMessage", defaultValue: "한 루틴당 최대 20개의 운동만 추가할 수 있습니다."))
        }
        .alert("다른 루틴 진행 중", isPresented: $showOtherActiveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("현재 진행 중인 루틴이 있습니다. 먼저 완료 후 다른 루틴을 시작할 수 있습니다.")
        }
        // 운동 완료 확인
        .alert("운동 완료", isPresented: $showFinishAlert) {
            Button("완료") {
                finishAndAskSync()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("루틴 운동을 완료하시겠습니까?")
        }
        // 루틴 반영 여부 확인
        .alert("루틴에 반영", isPresented: $showSyncRoutineAlert) {
            Button("반영") {
                syncChangesToRoutine()
                commitWorkout(syncRoutine: true)
            }
            Button("반영 안 함") {
                commitWorkout(syncRoutine: false)
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("수정된 세트 값(무게, 횟수, 가동범위 등)을 루틴 기본값에 반영하시겠습니까?")
        }
    }
    
    private func finishAndAskSync() {
        if hasChangesFromOriginal {
            showSyncRoutineAlert = true
        } else {
            commitWorkout(syncRoutine: false)
        }
    }
    
    /// 루틴 세트 기본값을 현재 수행한 세트 값으로 업데이트
    private func syncChangesToRoutine() {
        for rExercise in sortedExercises {
            let sortedSets = rExercise.sets.sorted { $0.order < $1.order }
            for rSet in sortedSets where completedSets.contains(rSet.id) {
                // rSet 값은 이미 유저가 수정했으므로 그대로 유지 (RoutineSet이 바인딩됨)
                _ = rSet // 이미 @Model이므로 자동 반영
            }
        }
    }
    
    /// 실제 WorkoutRecord를 저장하고 세션 종료
    private func commitWorkout(syncRoutine: Bool) {
        let today = Date()
        
        for rExercise in sortedExercises {
            guard let exercise = rExercise.exercise else { continue }
            
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
            
            // 루틴에 반영: 완료된 첫 번째 세트 기준으로 루틴 세트들 값 업데이트
            if syncRoutine {
                let routineSets = rExercise.sets.sorted { $0.order < $1.order }
                for (i, rSet) in routineSets.enumerated() {
                    if i < sortedSets.count {
                        let src = sortedSets[i]
                        rSet.weight = src.weight
                        rSet.reps = src.reps
                        rSet.timeDuration = src.timeDuration
                        rSet.rangeOfMotion = src.rangeOfMotion
                    }
                }
            }
        }
        
        _ = RestTimerManager.shared.stop()
        session.end()
        completedSets = []
        
        NotificationCenter.default.post(name: .switchToHomeTab, object: nil)
        dismiss()
    }
}

// MARK: - Exercise Section

struct RoutineExerciseSection: View {
    @Environment(\.modelContext) private var modelContext
    let rExercise: RoutineExercise
    let routine: Routine
    let isWorkoutActive: Bool
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
                    
                    // 항상 편집 메뉴 표시 (운동 중에도 삭제 가능)
                    Menu {
                        if !isWorkoutActive {
                            Button {
                                onReplace()
                            } label: {
                                Label(String(localized: "common.change", defaultValue: "변경"), systemImage: "arrow.2.squarepath")
                            }
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
                
                // 세트 +/- 버튼 (항상 표시, 운동 중에도 가능)
                HStack(spacing: 12) {
                    Button {
                        removeLastSet()
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.title3)
                    }
                    .disabled(sortedSets.isEmpty)
                    
                    Text(String(localized: "common.set", defaultValue: "세트"))
                        .font(.subheadline).bold()
                    
                    Button {
                        addSet()
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            
            // Sets
            VStack(spacing: 4) {
                ForEach(sortedSets) { rSet in
                    RoutineSetRow(
                        rSet: rSet,
                        type: rExercise.type,
                        isWorkoutActive: isWorkoutActive,
                        completedSets: $completedSets,
                        onDelete: {
                            modelContext.delete(rSet)
                            reorderSets()
                        },
                        isLastSet: rSet == sortedSets.last
                    )
                    
                    if rSet.restTimeAfterSet > 0 && rSet != sortedSets.last {
                        HStack {
                            Spacer()
                            Image(systemName: "timer")
                            Text(formatDuration(rSet.restTimeAfterSet))
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
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
    
    private func addSet() {
        let newOrder = (sortedSets.last?.order ?? 0) + 1
        let newSet = RoutineSet(order: newOrder)
        if let lastSet = sortedSets.last {
            newSet.weight = lastSet.weight
            newSet.reps = lastSet.reps
            newSet.timeDuration = lastSet.timeDuration
            newSet.rangeOfMotion = lastSet.rangeOfMotion
        }
        rExercise.sets.append(newSet)
        modelContext.insert(newSet)
        newSet.routineExercise = rExercise
    }
    
    private func removeLastSet() {
        guard let lastSet = sortedSets.last else { return }
        completedSets.remove(lastSet.id)
        modelContext.delete(lastSet)
        reorderSets()
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

// MARK: - Set Row

struct RoutineSetRow: View {
    @Bindable var rSet: RoutineSet
    let type: ExerciseType
    let isWorkoutActive: Bool
    @Binding var completedSets: Set<UUID>
    let onDelete: () -> Void
    let isLastSet: Bool
    
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
                if isWorkoutActive {
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
                    .sensoryFeedback(.success, trigger: isCompleted)
                } else {
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
                        Text("kg").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        TextField("0", value: $rSet.reps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3).bold()
                            .frame(width: 60)
                        Text("회").font(.subheadline).foregroundStyle(.secondary)
                    }
                } else if type == .repsOnly {
                    Spacer()
                    HStack(spacing: 2) {
                        TextField("0", value: $rSet.reps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3).bold()
                            .frame(width: 60)
                        Text("회").font(.subheadline).foregroundStyle(.secondary)
                    }
                } else {
                    Spacer()
                    HStack(spacing: 2) {
                        TextField("0", value: $rSet.timeDuration, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3).bold()
                            .frame(width: 60)
                        Text("초").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                
                Button { onDelete() } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 8)
                        .frame(width: 24, height: 24)
                }
            }
            
            // ROM 슬라이더 (타입에 따라, 항상 표시)
            if type != .timeOnly {
                ROMSliderView(value: $rSet.rangeOfMotion, disabled: false)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
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
            if !isTimerActiveForThis && !isLastSet {
                timerManager.start(for: rSet.id)
            }
        }
    }
}

// MARK: - Exercise Picker (단일 교체)

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
                                        Text(exercise.type.displayName).font(.caption).foregroundStyle(.secondary)
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
                                            Text(exercise.type.displayName).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedExercises.contains(exercise.id) {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
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
