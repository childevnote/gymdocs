import Foundation

struct ExerciseTranslator {
    static let shared = ExerciseTranslator()
    
    private var translationMap: [String: [String: String]] = [:]
    
    private init() {
        struct DefaultExerciseDTO: Codable {
            let names: [String: String]
        }
        
        guard let url = Bundle.main.url(forResource: "default_exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([DefaultExerciseDTO].self, from: data) else { return }
        
        var map: [String: [String: String]] = [:]
        for dto in dtos {
            for name in dto.names.values {
                map[name] = dto.names
            }
        }
        self.translationMap = map
    }
    
    func localizedName(for name: String) -> String {
        guard let names = translationMap[name] else { return name }
        
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        let baseLang = langCode.hasPrefix("ko") ? "ko" : (langCode.hasPrefix("ja") ? "ja" : "en")
        
        return names[baseLang] ?? names["en"] ?? name
    }
}
