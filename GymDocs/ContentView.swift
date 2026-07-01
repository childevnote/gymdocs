import SwiftUI
import SwiftData

extension Notification.Name {
    static let switchToHomeTab = Notification.Name("switchToHomeTab")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appColorScheme") private var appColorScheme = 0 // 0: System, 1: Light, 2: Dark
    @AppStorage("appLanguage") private var appLanguage = 0 // 0: System, 1: EN, 2: KO, 3: JA
    @State private var selectedTab = 0

    private var colorScheme: ColorScheme? {
        switch appColorScheme {
        case 1: return .light
        case 2: return .dark
        default: return nil // System
        }
    }

    private var appLocale: Locale {
        switch appLanguage {
        case 1: return Locale(identifier: "en")
        case 2: return Locale(identifier: "ko")
        case 3: return Locale(identifier: "ja")
        default: return Locale.current
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(String(localized: "tab.home", defaultValue: "홈"), systemImage: "house.fill")
                }
                .tag(0)

            RoutineListView()
                .tabItem {
                    Label(String(localized: "tab.routines", defaultValue: "루틴"), systemImage: "list.bullet.clipboard.fill")
                }
                .tag(1)

            ExerciseListView()
                .tabItem {
                    Label(String(localized: "tab.exercises", defaultValue: "운동"), systemImage: "dumbbell.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label(String(localized: "tab.settings", defaultValue: "설정"), systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Color(hex: "FFD52E"))
        .preferredColorScheme(colorScheme)
        .environment(\.locale, appLocale)
        .fullScreenCover(isPresented: .init(get: { !hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView()
        }
        .onAppear {
            if exercises.isEmpty {
                Exercise.seedDefaultExercises(into: modelContext)
            } else {
                // Cleanup bad data (body parts saved as exercises)
                let badNames = ["가슴", "등", "하체", "어깨", "이두", "삼두", "전완근", "코어/복근", "코어", "복근", "유산소", "전신", "스트레칭", "기타", "Chest", "Back", "Legs", "Shoulders", "Biceps", "Triceps", "Forearms", "Core/Abs", "Cardio", "Full Body", "Stretching", "Other", "Core", "胸", "背中", "脚", "肩", "上腕二頭筋", "上腕三頭筋", "前腕", "腹筋/体幹", "有酸素", "全身", "ストレッチ", "その他"]
                let badExercises = exercises.filter { badNames.contains($0.name) }
                for ex in badExercises {
                    modelContext.delete(ex)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToHomeTab)) { _ in
            selectedTab = 0
        }
    }
}

