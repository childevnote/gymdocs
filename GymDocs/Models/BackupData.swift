import Foundation

struct BackupData: Codable {
    var version: Int = 1
    var settings: SettingsDTO?
    let exercises: [ExerciseDTO]
    let records: [WorkoutRecordDTO]
    let sets: [SetRecordDTO]
    var routines: [RoutineDTO]?
    var routineExercises: [RoutineExerciseDTO]?
}

struct SettingsDTO: Codable {
    let hasCompletedOnboarding: Bool
    let userHeight: Double
    let userWeight: Double
}

struct RoutineDTO: Codable {
    let id: UUID
    let name: String
    let createdAt: Date

    init(from routine: Routine) {
        self.id = routine.id
        self.name = routine.name
        self.createdAt = routine.createdAt
    }
}

struct RoutineExerciseDTO: Codable {
    let id: UUID
    let order: Int
    let type: ExerciseType
    let exerciseId: UUID?
    let routineId: UUID?

    init(from routineEx: RoutineExercise) {
        self.id = routineEx.id
        self.order = routineEx.order
        self.type = routineEx.type
        self.exerciseId = routineEx.exercise?.id
        self.routineId = routineEx.routine?.id
    }
}

struct ExerciseDTO: Codable {
    let id: UUID
    let name: String
    let type: ExerciseType
    let bodyPart: BodyPart
    let createdAt: Date

    init(from exercise: Exercise) {
        self.id = exercise.id
        self.name = exercise.name
        self.type = exercise.type
        self.bodyPart = exercise.bodyPart
        self.createdAt = exercise.createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, bodyPart, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(ExerciseType.self, forKey: .type)
        bodyPart = try container.decodeIfPresent(BodyPart.self, forKey: .bodyPart) ?? .other
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct WorkoutRecordDTO: Codable {
    let id: UUID
    let date: Date
    let exerciseId: UUID

    init(from record: WorkoutRecord) {
        self.id = record.id
        self.date = record.date
        self.exerciseId = record.exercise?.id ?? UUID()
    }
}

struct SetRecordDTO: Codable {
    let id: UUID
    let order: Int
    let weight: Double
    let reps: Int
    let timeDuration: Int
    let restTimeAfterSet: Int
    let rangeOfMotion: RangeOfMotion
    let isCompleted: Bool
    let workoutRecordId: UUID

    init(from setRecord: SetRecord) {
        self.id = setRecord.id
        self.order = setRecord.order
        self.weight = setRecord.weight
        self.reps = setRecord.reps
        self.timeDuration = setRecord.timeDuration
        self.restTimeAfterSet = setRecord.restTimeAfterSet
        self.rangeOfMotion = setRecord.rangeOfMotion
        self.isCompleted = setRecord.isCompleted
        self.workoutRecordId = setRecord.workoutRecord?.id ?? UUID()
    }

    enum CodingKeys: String, CodingKey {
        case id, order, weight, reps, timeDuration, restTimeAfterSet, rangeOfMotion, isCompleted, workoutRecordId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        order = try container.decode(Int.self, forKey: .order)
        weight = try container.decode(Double.self, forKey: .weight)
        reps = try container.decode(Int.self, forKey: .reps)
        timeDuration = try container.decode(Int.self, forKey: .timeDuration)
        restTimeAfterSet = try container.decode(Int.self, forKey: .restTimeAfterSet)
        rangeOfMotion = try container.decodeIfPresent(RangeOfMotion.self, forKey: .rangeOfMotion) ?? .normal
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        workoutRecordId = try container.decode(UUID.self, forKey: .workoutRecordId)
    }
}

