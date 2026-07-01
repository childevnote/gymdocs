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
                let bwMult = exercise.bodyweightMultiplier
                let assistMult = exercise.machineAssistMultiplier
                return completed.reduce(0) { $0 + (max(0, (userWeight * bwMult) - ($1.weight * assistMult)) * Double($1.reps)) }
            }
            return completed.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        case .repsOnly:
            if userWeight > 0 {
                let bwMult = exercise.bodyweightMultiplier
                return completed.reduce(0) { $0 + ((userWeight * bwMult) * Double($1.reps)) }
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
            return completed.enumerated().reduce(0) { total, pair in
                let (index, setRecord) = pair
                let baseVolume = setRecord.weight * Double(setRecord.reps)
                let romMult = setRecord.rangeOfMotion.multiplier
                
                let isLastSet = index == (completed.count - 1)
                let rest = Double(setRecord.restTimeAfterSet)
                var restMult = 1.0
                if !isLastSet {
                    if rest <= 180.0 {
                        let effectiveRest = max(30.0, rest)
                        restMult += (180.0 - effectiveRest) / 300.0
                    } else if rest > 240.0 {
                        let overMinutes = (rest - 240.0) / 60.0
                        let penalty = min(0.2, overMinutes * 0.01)
                        restMult -= penalty
                    }
                }
                
                return total + (baseVolume * romMult * restMult)
            }
        case .repsOnly:
            let bwMult = exercise.bodyweightMultiplier
            return completed.enumerated().reduce(0) { total, pair in
                let (index, setRecord) = pair
                let weight = userWeight > 0 ? (userWeight * bwMult) : 1.0
                let baseVolume = weight * Double(setRecord.reps)
                let romMult = setRecord.rangeOfMotion.multiplier
                
                let isLastSet = index == (completed.count - 1)
                let rest = Double(setRecord.restTimeAfterSet)
                var restMult = 1.0
                if !isLastSet {
                    if rest <= 180.0 {
                        let effectiveRest = max(30.0, rest)
                        restMult += (180.0 - effectiveRest) / 300.0
                    } else if rest > 240.0 {
                        let overMinutes = (rest - 240.0) / 60.0
                        let penalty = min(0.2, overMinutes * 0.01)
                        restMult -= penalty
                    }
                }
                
                return total + (baseVolume * romMult * restMult)
            }
        case .timeOnly:
            return completed.reduce(0) { total, setRecord in
                let baseVolume = Double(setRecord.timeDuration)
                return total + baseVolume
            }
        case .assistedWeightAndReps:
            let bwMult = exercise.bodyweightMultiplier
            let assistMult = exercise.machineAssistMultiplier
            return completed.enumerated().reduce(0) { total, pair in
                let (index, setRecord) = pair
                let effectiveWeight = userWeight > 0 ? max(0, (userWeight * bwMult) - (setRecord.weight * assistMult)) : setRecord.weight
                let baseVolume = effectiveWeight * Double(setRecord.reps)
                let romMult = setRecord.rangeOfMotion.multiplier
                
                let isLastSet = index == (completed.count - 1)
                let rest = Double(setRecord.restTimeAfterSet)
                var restMult = 1.0
                if !isLastSet {
                    if rest <= 180.0 {
                        let effectiveRest = max(30.0, rest)
                        restMult += (180.0 - effectiveRest) / 300.0
                    } else if rest > 240.0 {
                        let overMinutes = (rest - 240.0) / 60.0
                        let penalty = min(0.2, overMinutes * 0.01)
                        restMult -= penalty
                    }
                }
                
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

fileprivate extension Exercise {
    var bodyweightMultiplier: Double {
        let n = name.lowercased()
        if n.contains("push-up") || n.contains("푸시업") || n.contains("푸쉬업") {
            return 0.64 // ~64% of bodyweight (leverage effect)
        } else if n.contains("pull-up") || n.contains("풀업") || n.contains("턱걸이") || n.contains("dip") || n.contains("딥스") || n.contains("chin-up") {
            return 0.94 // ~94% of bodyweight (excluding hands/forearms)
        } else if n.contains("squat") || n.contains("스쿼트") || n.contains("lunge") || n.contains("런지") || n.contains("pistol") {
            return 0.88 // ~88% of bodyweight (excluding lower legs/feet)
        }
        return 0.90 // general fallback for other bodyweight exercises
    }
    
    var machineAssistMultiplier: Double {
        return 0.95 // ~5% friction loss in standard pulley machines
    }
}
