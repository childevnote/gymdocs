import Foundation
import SwiftData

enum RangeOfMotion: String, Codable, CaseIterable {
    case full
    case eccentric
    case concentric
    case normal
    
    var multiplier: Double {
        switch self {
        case .full: return 1.15
        case .eccentric: return 1.1
        case .concentric: return 0.95
        case .normal: return 1.0
        }
    }
    
    var displayName: String {
        switch self {
        case .full: return String(localized: "rom.full", defaultValue: "전가동범위")
        case .eccentric: return String(localized: "rom.eccentric", defaultValue: "네거티브(신장성)")
        case .concentric: return String(localized: "rom.concentric", defaultValue: "포지티브(단축성)")
        case .normal: return String(localized: "rom.normal", defaultValue: "일반")
        }
    }
}

@Model
final class SetRecord {
    @Attribute(.unique) var id: UUID
    var order: Int
    var weight: Double
    var reps: Int
    var timeDuration: Int   // seconds
    var restTimeAfterSet: Int // seconds
    var rangeOfMotion: RangeOfMotion
    var isCompleted: Bool
    var workoutRecord: WorkoutRecord?

    init(order: Int, workoutRecord: WorkoutRecord) {
        self.id = UUID()
        self.order = order
        self.weight = 0
        self.reps = 0
        self.timeDuration = 0
        self.restTimeAfterSet = 0
        self.rangeOfMotion = .normal
        self.isCompleted = false
        self.workoutRecord = workoutRecord
    }
}
