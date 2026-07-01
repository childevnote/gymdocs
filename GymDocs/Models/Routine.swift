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
final class RoutineSet {
    @Attribute(.unique) var id: UUID
    var order: Int
    var weight: Double
    var reps: Int
    var timeDuration: Int
    var rangeOfMotion: RangeOfMotion
    var restTimeAfterSet: Int = 0
    
    var routineExercise: RoutineExercise?

    init(order: Int, weight: Double = 0, reps: Int = 0, timeDuration: Int = 0, rangeOfMotion: RangeOfMotion = .normal) {
        self.id = UUID()
        self.order = order
        self.weight = weight
        self.reps = reps
        self.timeDuration = timeDuration
        self.rangeOfMotion = rangeOfMotion
    }
}

@Model
final class RoutineExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var type: ExerciseType
    
    var exercise: Exercise?
    var routine: Routine?
    
    @Relationship(deleteRule: .cascade, inverse: \RoutineSet.routineExercise)
    var sets: [RoutineSet]

    init(order: Int, type: ExerciseType, exercise: Exercise) {
        self.id = UUID()
        self.order = order
        self.type = type
        self.exercise = exercise
        self.sets = []
    }
}
