import SwiftUI
import SwiftData
import UIKit

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var record: WorkoutRecord
    var isLocked: Bool = false

    var body: some View {
        List {
            Section {
                ForEach(record.sortedSets) { setRecord in
                    SetRecordRow(setRecord: setRecord, exerciseType: record.exercise?.type ?? .weightAndReps, isLocked: isLocked)
                }
                .onDelete { indexSet in
                    if isLocked { return }
                    let sorted = record.sortedSets
                    for index in indexSet {
                        modelContext.delete(sorted[index])
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
        }
    }
}

struct SetRecordRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var setRecord: SetRecord
    let exerciseType: ExerciseType
    var isLocked: Bool = false
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
                    if setRecord.isCompleted && !isTimerActiveForThis {
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

            // ROM and Timer (moved above inputs)
            HStack {
                // Rest timer
                Button {
                    timerManager.toggle(for: setRecord.id) { elapsed in
                        setRecord.restTimeAfterSet = elapsed
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isTimerActiveForThis ? "stop.fill" : "timer")
                            .font(.caption)
                        if isTimerActiveForThis {
                            Text(formatDuration(timerManager.elapsedSeconds))
                                .font(.caption)
                                .monospacedDigit()
                        } else if setRecord.restTimeAfterSet > 0 {
                            Text(String(localized: "detail.rest") + ": " + formatDuration(setRecord.restTimeAfterSet))
                                .font(.caption)
                        } else {
                            Text(String(localized: "detail.startRest"))
                                .font(.caption)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(isTimerActiveForThis ? .red : .secondary)
                .disabled(isLocked)
                .sensoryFeedback(.impact(flexibility: .solid), trigger: isTimerActiveForThis)

                Spacer()

                // ROM Radio pills
                if exerciseType != .timeOnly {
                    HStack(spacing: 6) {
                        ForEach(RangeOfMotion.allCases, id: \.self) { rom in
                            Button {
                                setRecord.rangeOfMotion = rom
                            } label: {
                                Text(rom.displayName)
                                    .font(.system(size: 11, weight: setRecord.rangeOfMotion == rom ? .bold : .regular))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(setRecord.rangeOfMotion == rom ? Color(hex: "FFD52E") : Color.secondary.opacity(0.1))
                                    .foregroundStyle(setRecord.rangeOfMotion == rom ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(isLocked)
                        }
                    }
                }
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

