import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: ExerciseType
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutRecord.exercise)
    var records: [WorkoutRecord]

    init(name: String, type: ExerciseType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.createdAt = Date()
        self.records = []
    }
}

enum ExerciseType: String, Codable, CaseIterable {
    case weightAndReps
    case timeOnly

    var displayName: String {
        switch self {
        case .weightAndReps:
            return String(localized: "exerciseType.weightAndReps")
        case .timeOnly:
            return String(localized: "exerciseType.timeOnly")
        }
    }
}
