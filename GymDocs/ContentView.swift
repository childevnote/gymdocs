import SwiftUI
import SwiftData

extension Notification.Name {
    static let switchToHomeTab = Notification.Name("switchToHomeTab")
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0

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
        .fullScreenCover(isPresented: .init(get: { !hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView()
        }
        .onAppear {
            if exercises.isEmpty {
                Exercise.seedDefaultExercises(into: modelContext)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToHomeTab)) { _ in
            selectedTab = 0
        }
    }
}

