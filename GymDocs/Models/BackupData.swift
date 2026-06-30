import Foundation

struct BackupData: Codable {
    let exercises: [ExerciseDTO]
    let records: [WorkoutRecordDTO]
    let sets: [SetRecordDTO]
}

struct ExerciseDTO: Codable {
    let id: UUID
    let name: String
    let type: ExerciseType
    let createdAt: Date

    init(from exercise: Exercise) {
        self.id = exercise.id
        self.name = exercise.name
        self.type = exercise.type
        self.createdAt = exercise.createdAt
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
    let isCompleted: Bool
    let workoutRecordId: UUID

    init(from setRecord: SetRecord) {
        self.id = setRecord.id
        self.order = setRecord.order
        self.weight = setRecord.weight
        self.reps = setRecord.reps
        self.timeDuration = setRecord.timeDuration
        self.restTimeAfterSet = setRecord.restTimeAfterSet
        self.isCompleted = setRecord.isCompleted
        self.workoutRecordId = setRecord.workoutRecord?.id ?? UUID()
    }
}
