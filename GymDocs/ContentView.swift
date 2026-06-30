import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(String(localized: "tab.home"), systemImage: "house.fill")
                }

            ExerciseListView()
                .tabItem {
                    Label(String(localized: "tab.exercises"), systemImage: "dumbbell.fill")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "tab.settings"), systemImage: "gearshape.fill")
                }
        }
    }
}
