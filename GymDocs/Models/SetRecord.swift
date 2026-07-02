import Foundation
import SwiftData

enum RangeOfMotion: String, Codable, CaseIterable {
    // allCases order = left to right on slider: normal, concentric, eccentric, full
    case normal
    case concentric
    case eccentric
    case full
    
    var multiplier: Double {
        switch self {
        case .normal: return 1.0
        case .concentric: return 0.95
        case .eccentric: return 1.1
        case .full: return 1.15
        }
    }
    
    var displayName: String {
        switch self {
        case .normal: return String(localized: "rom.normal", defaultValue: "일반")
        case .concentric: return String(localized: "rom.concentric", defaultValue: "수축")
        case .eccentric: return String(localized: "rom.eccentric", defaultValue: "신장")
        case .full: return String(localized: "rom.full", defaultValue: "전범위")
        }
    }
    
    var sliderIndex: Int {
        switch self {
        case .normal: return 0
        case .concentric: return 1
        case .eccentric: return 2
        case .full: return 3
        }
    }
    
    static func fromSliderIndex(_ index: Int) -> RangeOfMotion {
        switch index {
        case 1: return .concentric
        case 2: return .eccentric
        case 3: return .full
        default: return .normal
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
