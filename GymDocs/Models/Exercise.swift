import Foundation
import SwiftData

// MARK: - Language Helper

/// 시스템 언어를 ko/ja/en 중 하나로 정규화 (앱 전역 공통 사용)
var preferredLanguageCode: String {
    let id = Locale.current.language.languageCode?.identifier ?? "en"
    if id.hasPrefix("ko") { return "ko" }
    if id.hasPrefix("ja") { return "ja" }
    return "en"
}

// MARK: - BodyPart

enum BodyPart: String, Codable, CaseIterable {
    case chest, back, legs, shoulders, biceps, triceps, forearms, core, cardio, fullBody, stretching, other

    var displayName: String {
        // 각 케이스별 ko/ja/en 이름 테이블
        switch (self, preferredLanguageCode) {
        case (.chest,      "ko"): return "가슴"
        case (.chest,      "ja"): return "胸"
        case (.chest,        _): return "Chest"
        case (.back,       "ko"): return "등"
        case (.back,       "ja"): return "背中"
        case (.back,         _): return "Back"
        case (.legs,       "ko"): return "하체"
        case (.legs,       "ja"): return "脚"
        case (.legs,         _): return "Legs"
        case (.shoulders,  "ko"): return "어깨"
        case (.shoulders,  "ja"): return "肩"
        case (.shoulders,    _): return "Shoulders"
        case (.biceps,     "ko"): return "이두"
        case (.biceps,     "ja"): return "上腕二頭筋"
        case (.biceps,       _): return "Biceps"
        case (.triceps,    "ko"): return "삼두"
        case (.triceps,    "ja"): return "上腕三頭筋"
        case (.triceps,      _): return "Triceps"
        case (.forearms,   "ko"): return "전완근"
        case (.forearms,   "ja"): return "前腕"
        case (.forearms,     _): return "Forearms"
        case (.core,       "ko"): return "코어/복근"
        case (.core,       "ja"): return "腹筋/体幹"
        case (.core,         _): return "Core/Abs"
        case (.cardio,     "ko"): return "유산소"
        case (.cardio,     "ja"): return "有酸素"
        case (.cardio,       _): return "Cardio"
        case (.fullBody,   "ko"): return "전신"
        case (.fullBody,   "ja"): return "全身"
        case (.fullBody,     _): return "Full Body"
        case (.stretching, "ko"): return "스트레칭"
        case (.stretching, "ja"): return "ストレッチ"
        case (.stretching,   _): return "Stretching"
        case (.other,      "ko"): return "기타"
        case (.other,      "ja"): return "その他"
        case (.other,        _): return "Other"
        }
    }
}

// MARK: - ExerciseType

enum ExerciseType: String, Codable, CaseIterable {
    case weightAndReps
    case assistedWeightAndReps
    case repsOnly
    case timeOnly

    var displayName: String {
        switch self {
        case .weightAndReps:         return String(localized: "exerciseType.weightAndReps")
        case .assistedWeightAndReps: return String(localized: "exerciseType.assistedWeightAndReps")
        case .repsOnly:              return String(localized: "exerciseType.repsOnly")
        case .timeOnly:              return String(localized: "exerciseType.timeOnly")
        }
    }
}

// MARK: - Exercise Model

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var code: String?
    var name: String
    var type: ExerciseType
    var bodyPart: BodyPart
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutRecord.exercise)
    var records: [WorkoutRecord]

    init(code: String? = nil, name: String, type: ExerciseType, bodyPart: BodyPart = .other) {
        self.id = UUID()
        self.code = code
        self.name = name
        self.type = type
        self.bodyPart = bodyPart
        self.createdAt = Date()
        self.records = []
    }

    var localizedName: String {
        if let code = code, let localized = ExerciseTranslator.shared.localizedName(forCode: code) {
            return localized
        }
        return ExerciseTranslator.shared.localizedName(forLegacyName: name)
    }

    var localizedDesc: String {
        if let code = code, let desc = ExerciseTranslator.shared.localizedDesc(forCode: code) {
            return desc
        }
        return ""
    }
}

// MARK: - Seed

extension Exercise {
    static func seedDefaultExercises(into context: ModelContext) {
        struct DTO: Codable {
            let code: String
            let names: [String: String]
            let desc: [String: String]?
            let type: ExerciseType
            let bodyPart: BodyPart
        }

        guard let url = Bundle.main.url(forResource: "default_exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([DTO].self, from: data)
        else { return }

        let lang = preferredLanguageCode
        for dto in dtos {
            let name = dto.names[lang] ?? dto.names["en"] ?? "Unknown"
            context.insert(Exercise(code: dto.code, name: name, type: dto.type, bodyPart: dto.bodyPart))
        }
    }
}
