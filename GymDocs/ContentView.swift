import SwiftUI
import SwiftData

// MARK: - Global Notifications

extension Notification.Name {
    static let switchToHomeTab = Notification.Name("switchToHomeTab")
    static let startWorkoutWithRoutine = Notification.Name("startWorkoutWithRoutine")
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = (int >> 16) & 0xFF
        let g = (int >> 8)  & 0xFF
        let b =  int        & 0xFF
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @Query private var routines: [Routine]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appColorScheme") private var appColorScheme = 0 // 0=System 1=Light 2=Dark
    @AppStorage("appLanguage")    private var appLanguage    = 0 // 0=System 1=EN 2=KO 3=JA
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var showLanguageRestartAlert = false
    @State private var showStartRoutineSheet = false
    @State private var session = ActiveRoutineSession.shared

    private var colorScheme: ColorScheme? {
        switch appColorScheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
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
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                .tabItem { Label(String(localized: "tab.home", defaultValue: "홈"), systemImage: "house.fill") }
                .tag(0)

            RoutineListView()
                .tabItem { Label(String(localized: "tab.routines", defaultValue: "루틴"), systemImage: "list.bullet.clipboard.fill") }
                .tag(1)

            Text("시작 화면")
                .tabItem { Label(String(localized: "tab.start", defaultValue: "시작"), systemImage: "play.circle.fill") }
                .tag(2)

            ExerciseListView()
                .tabItem { Label(String(localized: "tab.exercises", defaultValue: "운동"), systemImage: "dumbbell.fill") }
                .tag(3)

            AnalysisView()
                .tabItem { Label(String(localized: "tab.analysis", defaultValue: "분석"), systemImage: "chart.bar.fill") }
                .tag(4)

            SettingsView()
                .tabItem { Label(String(localized: "tab.settings", defaultValue: "설정"), systemImage: "gearshape.fill") }
                .tag(5)
            }
            
            if session.isActive && !session.isViewingActiveRoutine {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            if let id = session.activeRoutineID {
                                selectedTab = 0
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    NotificationCenter.default.post(name: .startWorkoutWithRoutine, object: id)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.run")
                                Text(String(localized: "home.activeWorkout", defaultValue: "진행 중인 운동"))
                            }
                            .font(.headline)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 4, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 64)
                    }
                }
            }
        }
        .tint(.primary)
        .preferredColorScheme(colorScheme)
        .environment(\.locale, appLocale)
        .fullScreenCover(isPresented: .init(get: { !hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView()
        }
        .onAppear {
            if exercises.isEmpty {
                Exercise.seedDefaultExercises(into: modelContext)
            } else {
                cleanupBadExerciseData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToHomeTab)) { _ in
            selectedTab = 0
        }
        .onChange(of: selectedTab) { old, new in
            if new == 2 {
                // Intercept "Start" tab
                selectedTab = old
                showStartRoutineSheet = true
            } else {
                previousTab = new
            }
        }
        .onChange(of: appLanguage) { _, newValue in
            // AppleLanguages에 저장해두면 다음 실행 시 해당 언어 번들이 자동 로드됨
            let langId: String? = switch newValue {
                case 1: "en"
                case 2: "ko"
                case 3: "ja"
                default: nil
            }
            if let id = langId {
                UserDefaults.standard.set([id], forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
            showLanguageRestartAlert = true
        }
        .alert("언어 변경 적용", isPresented: $showLanguageRestartAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("언어 변경이 저장되었습니다.\n앱을 완전히 종료 후 다시 실행하면 선택한 언어로 표시됩니다.")
        }
        .sheet(isPresented: $showStartRoutineSheet) {
            StartRoutineSelectionView(routines: routines, isPresented: $showStartRoutineSheet) { selectedRoutine in
                showStartRoutineSheet = false
                selectedTab = 0 // Switch to Home tab first
                ActiveRoutineSession.shared.start(routineID: selectedRoutine.id)
                // Slight delay to allow tab switch to settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .startWorkoutWithRoutine, object: selectedRoutine.id)
                }
            }
        }
    }

    // MARK: - Private

    private static let badExerciseNames: Set<String> = [
        "가슴", "등", "하체", "어깨", "이두", "삼두", "전완근", "코어/복근", "코어", "복근",
        "유산소", "전신", "스트레칭", "기타",
        "Chest", "Back", "Legs", "Shoulders", "Biceps", "Triceps", "Forearms",
        "Core/Abs", "Cardio", "Full Body", "Stretching", "Other", "Core",
        "胸", "背中", "脚", "肩", "上腕二頭筋", "上腕三頭筋", "前腕", "腹筋/体幹", "有酸素", "全身", "ストレッチ", "その他"
    ]

    /// 부위명이 운동 종목으로 잘못 저장된 데이터를 제거
    private func cleanupBadExerciseData() {
        let bad = exercises.filter { Self.badExerciseNames.contains($0.name) }
        bad.forEach { modelContext.delete($0) }
    }
}
