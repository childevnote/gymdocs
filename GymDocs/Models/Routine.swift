import Foundation
import SwiftData

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.exercises = []
    }
}

@Model
final class RoutineExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var type: ExerciseType
    
    var exercise: Exercise?
    var routine: Routine?

    init(order: Int, type: ExerciseType, exercise: Exercise) {
        self.id = UUID()
        self.order = order
        self.type = type
        self.exercise = exercise
    }
}
