import SwiftUI
import SwiftData
import UIKit

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var record: WorkoutRecord
    var isLocked: Bool = false
    var timerManager = RestTimerManager.shared

    var body: some View {
        List {
            Section {
                ForEach(record.sortedSets) { setRecord in
                    VStack(spacing: 4) {
                        SetRecordRow(
                            setRecord: setRecord,
                            exerciseType: record.exercise?.type ?? .weightAndReps,
                            isLocked: isLocked,
                            isLastSet: setRecord == record.sortedSets.last
                        )
                        
                        if setRecord.restTimeAfterSet > 0 && setRecord != record.sortedSets.last {
                            HStack {
                                Spacer()
                                Image(systemName: "timer")
                                Text(formatDuration(setRecord.restTimeAfterSet))
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                        }
                    }
                    .contextMenu {
                        if !isLocked {
                            Button(role: .destructive) {
                                modelContext.delete(setRecord)
                            } label: {
                                Label(String(localized: "common.delete", defaultValue: "삭제"), systemImage: "trash")
                            }
                        }
                    }
                }

                Button {
                    let newOrder = record.sets.count + 1
                    let newSet = SetRecord(order: newOrder, workoutRecord: record)
                    if let lastSet = record.sortedSets.last {
                        newSet.weight = lastSet.weight
                        newSet.reps = lastSet.reps
                        newSet.timeDuration = lastSet.timeDuration
                        newSet.rangeOfMotion = lastSet.rangeOfMotion
                    }
                    modelContext.insert(newSet)
                } label: {
                    Label(String(localized: "detail.addSet"), systemImage: "plus.circle")
                }
                .disabled(isLocked)
            } header: {
                Text(record.exercise?.localizedName ?? "")
            } footer: {
                if record.exercise?.type == .weightAndReps {
                    Text(String(localized: "detail.totalVolume") + ": " + String(format: "%.0f kg", record.totalVolume))
                } else {
                    Text(String(localized: "detail.totalTime") + ": " + formatDuration(Int(record.totalVolume)))
                }
            }

            Section {
                NavigationLink(destination: ExerciseChartView(exercise: record.exercise!)) {
                    Label(String(localized: "detail.viewChart"), systemImage: "chart.bar.fill")
                }
            }
        }
        .navigationTitle(String(localized: "detail.title"))
        .navigationBarTitleDisplayMode(.inline)
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
        .safeAreaInset(edge: .bottom) {
            if !isLocked && timerManager.isRunning {
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
                           let s = record.sets.first(where: { $0.id == activeId }) {
                            let elapsed = timerManager.stop()
                            s.restTimeAfterSet = elapsed
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
                .padding(.bottom, 8)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            }
        }
    }
}

struct SetRecordRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var setRecord: SetRecord
    let exerciseType: ExerciseType
    var isLocked: Bool = false
    let isLastSet: Bool
    
    var timerManager = RestTimerManager.shared

    private var isTimerActiveForThis: Bool {
        timerManager.isRunning && timerManager.activeSetId == setRecord.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Set number and completion toggle
            HStack {
                Text(String(localized: "detail.set") + " \(setRecord.order)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    setRecord.isCompleted.toggle()
                    if setRecord.isCompleted && !isTimerActiveForThis && !isLastSet {
                        timerManager.start(for: setRecord.id)
                    } else if !setRecord.isCompleted && isTimerActiveForThis {
                        let elapsed = timerManager.stop()
                        setRecord.restTimeAfterSet = elapsed
                    }
                } label: {
                    Image(systemName: setRecord.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(setRecord.isCompleted ? Color(hex: "FFD52E") : .secondary)
                        .font(.system(size: 28, weight: .semibold))
                }
                .buttonStyle(.plain)
                .disabled(isLocked)
                .sensoryFeedback(.success, trigger: setRecord.isCompleted)
            }

            // ROM Slider (full width)
            if exerciseType != .timeOnly {
                ROMSliderView(value: $setRecord.rangeOfMotion, disabled: isLocked)
            }

            // Input fields based on exercise type (Bigger inputs with matching corners)
            if exerciseType == .weightAndReps || exerciseType == .assistedWeightAndReps {
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text(exerciseType == .assistedWeightAndReps ? String(localized: "detail.assistWeight") : String(localized: "detail.weight"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $setRecord.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    VStack(alignment: .leading) {
                        Text(String(localized: "detail.reps"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $setRecord.reps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            } else if exerciseType == .repsOnly {
                VStack(alignment: .leading) {
                    Text(String(localized: "detail.reps"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $setRecord.reps, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            } else {
                VStack(alignment: .leading) {
                    Text(String(localized: "detail.duration"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $setRecord.timeDuration, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    Text(String(localized: "detail.seconds"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 8)
        .disabled(isLocked)
    }
}

