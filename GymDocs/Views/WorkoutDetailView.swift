import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var record: WorkoutRecord

    var body: some View {
        List {
            Section {
                ForEach(record.sortedSets) { setRecord in
                    SetRecordRow(setRecord: setRecord, exerciseType: record.exercise?.type ?? .weightAndReps)
                }
                .onDelete { indexSet in
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
            } header: {
                Text(record.exercise?.name ?? "")
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
    }
}

struct SetRecordRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var setRecord: SetRecord
    let exerciseType: ExerciseType
    private var timerManager = RestTimerManager.shared

    private var isTimerActiveForThis: Bool {
        timerManager.isRunning && timerManager.activeSetId == setRecord.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Set number and completion toggle
            HStack {
                Text(String(localized: "detail.set") + " \(setRecord.order)")
                    .font(.subheadline)
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
                        .foregroundStyle(setRecord.isCompleted ? .green : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            // Input fields based on exercise type
            if exerciseType == .weightAndReps || exerciseType == .assistedWeightAndReps {
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text(exerciseType == .assistedWeightAndReps ? String(localized: "detail.assistWeight") : String(localized: "detail.weight"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $setRecord.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading) {
                        Text(String(localized: "detail.reps"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $setRecord.reps, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            } else if exerciseType == .repsOnly {
                VStack(alignment: .leading) {
                    Text(String(localized: "detail.reps"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $setRecord.reps, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
            } else {
                VStack(alignment: .leading) {
                    Text(String(localized: "detail.duration"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $setRecord.timeDuration, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Text(String(localized: "detail.seconds"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // ROM
            if exerciseType != .timeOnly {
                HStack {
                    Picker("ROM", selection: $setRecord.rangeOfMotion) {
                        ForEach(RangeOfMotion.allCases, id: \.self) { rom in
                            Text(rom.displayName).tag(rom)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .controlSize(.mini)
                    
                    Spacer()
                }
            }

            // Rest timer
            HStack {
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
                .tint(isTimerActiveForThis ? .red : .blue)
            }
        }
        .padding(.vertical, 4)
    }
}

