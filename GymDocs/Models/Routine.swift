import Foundation
import SwiftData

/// 전역 루틴 운동 세션 상태 관리 (싱글톤)
@Observable
final class ActiveRoutineSession {
    static let shared = ActiveRoutineSession()
    /// 현재 진행 중인 루틴 ID (nil이면 비활성)
    var activeRoutineID: UUID? = nil
    
    /// 현재 유저가 활성화된 루틴 화면을 보고 있는지 여부
    var isViewingActiveRoutine: Bool = false
    
    private let storageKey = "ActiveRoutineSession_activeRoutineID"
    
    private init() {
        if let uuidString = UserDefaults.standard.string(forKey: storageKey),
           let id = UUID(uuidString: uuidString) {
            activeRoutineID = id
        }
    }
    
    var isActive: Bool { activeRoutineID != nil }
    
    func start(routineID: UUID) {
        activeRoutineID = routineID
        UserDefaults.standard.set(routineID.uuidString, forKey: storageKey)
    }
    
    func end() {
        activeRoutineID = nil
        isViewingActiveRoutine = false
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    func isCurrentRoutine(_ routineID: UUID) -> Bool {
        activeRoutineID == routineID
    }
}

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
