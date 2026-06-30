import Foundation
import SwiftData

enum BodyPart: String, Codable, CaseIterable {
    case chest, back, legs, shoulders, biceps, triceps, forearms, core, cardio, fullBody, stretching, other

    var displayName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let baseLang = lang.hasPrefix("ko") ? "ko" : (lang.hasPrefix("ja") ? "ja" : "en")
        
        switch self {
        case .chest: return baseLang == "ko" ? "가슴" : (baseLang == "ja" ? "胸" : "Chest")
        case .back: return baseLang == "ko" ? "등" : (baseLang == "ja" ? "背中" : "Back")
        case .legs: return baseLang == "ko" ? "하체" : (baseLang == "ja" ? "脚" : "Legs")
        case .shoulders: return baseLang == "ko" ? "어깨" : (baseLang == "ja" ? "肩" : "Shoulders")
        case .biceps: return baseLang == "ko" ? "이두" : (baseLang == "ja" ? "上腕二頭筋" : "Biceps")
        case .triceps: return baseLang == "ko" ? "삼두" : (baseLang == "ja" ? "上腕三頭筋" : "Triceps")
        case .forearms: return baseLang == "ko" ? "전완근" : (baseLang == "ja" ? "前腕" : "Forearms")
        case .core: return baseLang == "ko" ? "코어/복근" : (baseLang == "ja" ? "腹筋/体幹" : "Core/Abs")
        case .cardio: return baseLang == "ko" ? "유산소" : (baseLang == "ja" ? "有酸素" : "Cardio")
        case .fullBody: return baseLang == "ko" ? "전신" : (baseLang == "ja" ? "全身" : "Full Body")
        case .stretching: return baseLang == "ko" ? "스트레칭" : (baseLang == "ja" ? "ストレッチ" : "Stretching")
        case .other: return baseLang == "ko" ? "기타" : (baseLang == "ja" ? "その他" : "Other")
        }
    }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: ExerciseType
    var bodyPart: BodyPart
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutRecord.exercise)
    var records: [WorkoutRecord]

    init(name: String, type: ExerciseType, bodyPart: BodyPart = .other) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.bodyPart = bodyPart
        self.createdAt = Date()
        self.records = []
    }
}

enum ExerciseType: String, Codable, CaseIterable {
    case weightAndReps
    case assistedWeightAndReps
    case repsOnly
    case timeOnly

    var displayName: String {
        switch self {
        case .weightAndReps:
            return String(localized: "exerciseType.weightAndReps")
        case .assistedWeightAndReps:
            return String(localized: "exerciseType.assistedWeightAndReps")
        case .repsOnly:
            return String(localized: "exerciseType.repsOnly")
        case .timeOnly:
            return String(localized: "exerciseType.timeOnly")
        }
    }
}

extension Exercise {
    static func seedDefaultExercises(into context: ModelContext) {
        struct DefaultExerciseDTO: Codable {
            let names: [String: String]
            let type: ExerciseType
            let bodyPart: BodyPart
        }
        
        guard let url = Bundle.main.url(forResource: "default_exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([DefaultExerciseDTO].self, from: data) else { return }
        
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        let baseLang = langCode.hasPrefix("ko") ? "ko" : (langCode.hasPrefix("ja") ? "ja" : "en")
        
        for dto in dtos {
            let name = dto.names[baseLang] ?? dto.names["en"] ?? "Unknown"
            let exercise = Exercise(name: name, type: dto.type, bodyPart: dto.bodyPart)
            context.insert(exercise)
        }
    }
}
