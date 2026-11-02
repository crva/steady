import SwiftData
import SwiftUI

@main
struct SteadyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Habit.self, DayEntry.self])
    }
}
