import Foundation
import SwiftData

@Model
final class SetRecord {
    @Attribute(.unique) var id: UUID
    var order: Int
    var weight: Double
    var reps: Int
    var timeDuration: Int   // seconds
    var restTimeAfterSet: Int // seconds
    var isCompleted: Bool
    var workoutRecord: WorkoutRecord?

    init(order: Int, workoutRecord: WorkoutRecord) {
        self.id = UUID()
        self.order = order
        self.weight = 0
        self.reps = 0
        self.timeDuration = 0
        self.restTimeAfterSet = 0
        self.isCompleted = false
        self.workoutRecord = workoutRecord
    }
}
