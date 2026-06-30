import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \SetRecord.workoutRecord)
    var sets: [SetRecord]

    var sortedSets: [SetRecord] {
        sets.sorted { $0.order < $1.order }
    }

    /// Pure volume (uses userWeight for bodyweight/assisted exercises)
    var totalVolume: Double {
        guard let exercise else { return 0 }
        let completed = sets.filter { $0.isCompleted }
        let userWeight = UserDefaults.standard.double(forKey: "userWeight")
        switch exercise.type {
        case .weightAndReps:
            return completed.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        case .assistedWeightAndReps:
            if userWeight > 0 {
                return completed.reduce(0) { $0 + (max(0, userWeight - $1.weight) * Double($1.reps)) }
            }
            return completed.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        case .repsOnly:
            if userWeight > 0 {
                return completed.reduce(0) { $0 + (userWeight * Double($1.reps)) }
            }
            return completed.reduce(0) { $0 + Double($1.reps) }
        case .timeOnly:
            return completed.reduce(0) { $0 + Double($1.timeDuration) }
        }
    }
    
    /// Complex intensity score factoring in ROM, Rest, and RPE
    var intensityScore: Double {
        guard let exercise else { return 0 }
        let completed = sets.filter { $0.isCompleted }
        let userWeight = UserDefaults.standard.double(forKey: "userWeight")
        
        switch exercise.type {
        case .weightAndReps:
            return completed.reduce(0) { total, setRecord in
                let baseVolume = setRecord.weight * Double(setRecord.reps)
                let romMult = setRecord.rangeOfMotion.multiplier
                let restMult = 1.0 + max(0, (90.0 - Double(setRecord.restTimeAfterSet)) / 100.0)
                return total + (baseVolume * romMult * restMult)
            }
        case .repsOnly:
            return completed.reduce(0) { total, setRecord in
                let weight = userWeight > 0 ? userWeight : 1.0
                let baseVolume = weight * Double(setRecord.reps)
                let romMult = setRecord.rangeOfMotion.multiplier
                let restMult = 1.0 + max(0, (90.0 - Double(setRecord.restTimeAfterSet)) / 100.0)
                return total + (baseVolume * romMult * restMult)
            }
        case .timeOnly:
            return completed.reduce(0) { total, setRecord in
                let baseVolume = Double(setRecord.timeDuration)
                return total + baseVolume
            }
        case .assistedWeightAndReps:
            return completed.reduce(0) { total, setRecord in
                let effectiveWeight = userWeight > 0 ? max(0, userWeight - setRecord.weight) : setRecord.weight
                let baseVolume = effectiveWeight * Double(setRecord.reps)
                let romMult = setRecord.rangeOfMotion.multiplier
                let restMult = 1.0 + max(0, (90.0 - Double(setRecord.restTimeAfterSet)) / 100.0)
                return total + (baseVolume * romMult * restMult)
            }
        }
    }

    init(date: Date, exercise: Exercise) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.exercise = exercise
        self.sets = []
    }
}
