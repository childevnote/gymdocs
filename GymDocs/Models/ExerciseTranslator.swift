import Foundation

/// 운동 이름 다국어 번역 싱글톤.
/// 앱 실행 시 `default_exercises.json`을 한 번만 파싱하여 이름→번역 맵을 구성한다.
struct ExerciseTranslator {
    static let shared = ExerciseTranslator()

    private let translationMap: [String: [String: String]]

    private init() {
        struct DTO: Codable { let names: [String: String] }

        guard let url = Bundle.main.url(forResource: "default_exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([DTO].self, from: data)
        else {
            translationMap = [:]
            return
        }

        // 모든 언어별 이름을 키로 등록하여 어떤 언어 이름으로 조회해도 전체 맵 반환
        var map: [String: [String: String]] = [:]
        map.reserveCapacity(dtos.count * 3)
        for dto in dtos {
            for name in dto.names.values {
                map[name] = dto.names
            }
        }
        translationMap = map
    }

    func localizedName(for name: String) -> String {
        guard let names = translationMap[name] else { return name }
        return names[preferredLanguageCode] ?? names["en"] ?? name
    }

    // MARK: - Private

    // preferredLanguageCode는 Exercise.swift에서 전역으로 선언됨
}
