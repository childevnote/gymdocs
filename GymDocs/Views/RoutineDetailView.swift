import SwiftUI
import SwiftData
import UIKit

// MARK: - ROM Slider View
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
    
    // Summary
    @State private var showSummary = false
    @State private var summaryRecords: [WorkoutRecord] = []
    
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
            }
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
                .onMove { source, destination in
                    var list = sortedExercises
                    list.move(fromOffsets: source, toOffset: destination)
                    for (index, ex) in list.enumerated() {
                        ex.order = index
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
        .onAppear {
            if session.isCurrentRoutine(routine.id) {
                session.isViewingActiveRoutine = true
            }
        }
        .onDisappear {
            if session.isCurrentRoutine(routine.id) {
                session.isViewingActiveRoutine = false
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
        .fullScreenCover(isPresented: $showSummary, onDismiss: {
            NotificationCenter.default.post(name: .switchToHomeTab, object: nil)
            dismiss()
        }) {
            WorkoutSummaryView(records: summaryRecords)
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
        var newRecords: [WorkoutRecord] = []
        
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
            record.updateStats() // 추가: DB 반영
            newRecords.append(record)
            
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
        
        if !newRecords.isEmpty {
            self.summaryRecords = newRecords
            self.showSummary = true
        } else {
            NotificationCenter.default.post(name: .switchToHomeTab, object: nil)
            dismiss()
        }
    }
}

// MARK: - Exercise Section
