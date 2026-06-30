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

    /// Total volume: sum of (weight × reps) for weightAndReps, or sum of timeDuration for timeOnly
    var totalVolume: Double {
        guard let exercise else { return 0 }
        switch exercise.type {
        case .weightAndReps:
            return sets.filter { $0.isCompleted }.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        case .timeOnly:
            return sets.filter { $0.isCompleted }.reduce(0) { $0 + Double($1.timeDuration) }
        }
    }

    init(date: Date, exercise: Exercise) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.exercise = exercise
        self.sets = []
    }
}
