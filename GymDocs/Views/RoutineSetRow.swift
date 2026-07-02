import SwiftUI
import SwiftData

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
                    .buttonStyle(.hapticPress)
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
                .buttonStyle(.hapticPress(dimBackground: false))
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


