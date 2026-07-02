import Foundation

/// 운동 이름 다국어 번역 싱글톤.
/// 앱 실행 시 `default_exercises.json`을 한 번만 파싱하여 이름→번역 맵을 구성한다.
struct ExerciseTranslator {
    static let shared = ExerciseTranslator()

    private let codeMap: [String: (names: [String: String], desc: [String: String])]
    private let legacyMap: [String: [String: String]]

    private init() {
        struct DTO: Codable { 
            let code: String
            let names: [String: String]
            let desc: [String: String]
        }

        guard let url = Bundle.main.url(forResource: "default_exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([DTO].self, from: data)
        else {
            codeMap = [:]
            legacyMap = [:]
            return
        }

        var cMap: [String: (names: [String: String], desc: [String: String])] = [:]
        var lMap: [String: [String: String]] = [:]
        
        cMap.reserveCapacity(dtos.count)
        for dto in dtos {
            cMap[dto.code] = (names: dto.names, desc: dto.desc)
            for name in dto.names.values {
                lMap[name] = dto.names
            }
        }
        codeMap = cMap
        legacyMap = lMap
    }

    func localizedName(forCode code: String) -> String? {
        guard let names = codeMap[code]?.names else { return nil }
        return names[preferredLanguageCode] ?? names["en"]
    }

    func localizedDesc(forCode code: String) -> String? {
        guard let desc = codeMap[code]?.desc else { return nil }
        return desc[preferredLanguageCode] ?? desc["en"]
    }

    func localizedName(forLegacyName name: String) -> String {
        guard let names = legacyMap[name] else { return name }
        return names[preferredLanguageCode] ?? names["en"] ?? name
    }

    // MARK: - Private

    // preferredLanguageCode는 Exercise.swift에서 전역으로 선언됨
}
