import SwiftUI
import SwiftData

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
