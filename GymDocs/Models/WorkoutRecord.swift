import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var exercise: Exercise?
    var originRoutineID: UUID?

    @Relationship(deleteRule: .cascade, inverse: \SetRecord.workoutRecord)
    var sets: [SetRecord]

    var sortedSets: [SetRecord] {
        sets.sorted { $0.order < $1.order }
    }

    // MARK: - Denormalized Stats (반정규화)
    var totalVolume: Double = 0.0
    var intensityScore: Double = 0.0

    /// 세트가 추가/삭제/수정될 때 호출하여 통계값을 DB에 반영합니다.
    func updateStats() {
        guard let exercise else {
            totalVolume = 0
            intensityScore = 0
            return
        }
        let completed = completedSets
        guard !completed.isEmpty else {
            totalVolume = 0
            intensityScore = 0
            return
        }
        let userW = Self.userWeight
        totalVolume = Self.computeVolume(for: exercise, sets: completed, userWeight: userW)
        intensityScore = Self.computeIntensity(for: exercise, sets: completed, userWeight: userW)
    }

    init(date: Date, exercise: Exercise) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.exercise = exercise
        self.sets = []
    }

    // MARK: - Private Helpers

    private var completedSets: [SetRecord] {
        sets.filter { $0.isCompleted }
    }

    /// Cached user body weight from UserDefaults (called once per stat computation)
    private static var userWeight: Double {
        UserDefaults.standard.double(forKey: "userWeight")
    }

    private static func computeVolume(for exercise: Exercise, sets: [SetRecord], userWeight: Double) -> Double {
        switch exercise.type {
        case .weightAndReps:
            return sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        case .assistedWeightAndReps:
            let bw = exercise.bodyweightMultiplier
            let assist = exercise.machineAssistMultiplier
            if userWeight > 0 {
                return sets.reduce(0) { $0 + (max(0, (userWeight * bw) - ($1.weight * assist)) * Double($1.reps)) }
            }
            return sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        case .repsOnly:
            if userWeight > 0 {
                let bw = exercise.bodyweightMultiplier
                return sets.reduce(0) { $0 + ((userWeight * bw) * Double($1.reps)) }
            }
            return sets.reduce(0) { $0 + Double($1.reps) }
        case .timeOnly:
            return sets.reduce(0) { $0 + Double($1.timeDuration) }
        }
    }

    private static func computeIntensity(for exercise: Exercise, sets: [SetRecord], userWeight: Double) -> Double {
        let lastIndex = sets.count - 1

        func scoreSet(index: Int, set: SetRecord, baseVolume: Double) -> Double {
            let rom = set.rangeOfMotion.multiplier
            let rest = restMultiplier(seconds: Double(set.restTimeAfterSet), isLast: index == lastIndex)
            return baseVolume * rom * rest
        }

        switch exercise.type {
        case .weightAndReps:
            return sets.enumerated().reduce(0) { total, pair in
                total + scoreSet(index: pair.offset, set: pair.element,
                                 baseVolume: pair.element.weight * Double(pair.element.reps))
            }
        case .repsOnly:
            let bw = exercise.bodyweightMultiplier
            let w = userWeight > 0 ? userWeight * bw : 1.0
            return sets.enumerated().reduce(0) { total, pair in
                total + scoreSet(index: pair.offset, set: pair.element,
                                 baseVolume: w * Double(pair.element.reps))
            }
        case .assistedWeightAndReps:
            let bw = exercise.bodyweightMultiplier
            let assist = exercise.machineAssistMultiplier
            return sets.enumerated().reduce(0) { total, pair in
                let eff = userWeight > 0
                    ? max(0, (userWeight * bw) - (pair.element.weight * assist))
                    : pair.element.weight
                return total + scoreSet(index: pair.offset, set: pair.element,
                                        baseVolume: eff * Double(pair.element.reps))
            }
        case .timeOnly:
            // ROM/rest modifiers don't apply to timed exercises
            return sets.reduce(0) { $0 + Double($1.timeDuration) }
        }
    }

    /// Rest-time multiplier: bonus for short rests, penalty for very long rests.
    /// Last set is excluded (no subsequent set to recover for).
    private static func restMultiplier(seconds rest: Double, isLast: Bool) -> Double {
        guard !isLast else { return 1.0 }
        if rest <= 180 {
            return 1.0 + (180.0 - max(30.0, rest)) / 300.0
        } else if rest > 240 {
            return 1.0 - min(0.2, ((rest - 240.0) / 60.0) * 0.01)
        }
        return 1.0
    }
}

// MARK: - Bodyweight Multiplier (fileprivate — used only in WorkoutRecord)

fileprivate extension Exercise {
    /// Estimated fraction of bodyweight engaged (biomechanics-based)
    var bodyweightMultiplier: Double {
        let n = name.lowercased()
        if n.contains("push-up") || n.contains("푸시업") || n.contains("푸쉬업") { return 0.64 }
        if n.contains("pull-up") || n.contains("풀업") || n.contains("턱걸이")
            || n.contains("dip") || n.contains("딥스") || n.contains("chin-up") { return 0.94 }
        if n.contains("squat") || n.contains("스쿼트") || n.contains("lunge")
            || n.contains("런지") || n.contains("pistol") { return 0.88 }
        return 0.90
    }

    /// ~5% friction loss in standard pulley-assist machines
    var machineAssistMultiplier: Double { 0.95 }
}
