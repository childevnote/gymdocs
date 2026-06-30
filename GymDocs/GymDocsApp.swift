import SwiftUI
import SwiftData

@main
struct GymDocsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Exercise.self, WorkoutRecord.self, SetRecord.self])
    }
}
