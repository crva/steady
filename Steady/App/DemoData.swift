#if DEBUG
import Foundation
import SwiftData

/// Sample habits for simulator screenshots. Launch with `-seedDemoData`.
@MainActor
enum DemoData {
    static func seedIfRequested(appState: AppState, service: HabitService) {
        guard CommandLine.arguments.contains("-seedDemoData") else { return }
        let existing = (try? service.context.fetchCount(FetchDescriptor<Habit>())) ?? 0
        guard existing == 0 else { return }
        appState.storageMode = .local

        let today = appState.todayKey
        var read = HabitDraft()
        read.name = "Read 20 pages"
        read.emoji = "📚"
        read.color = .teal
        read.countingMode = .strict
        read.startDate = DayKey.startOfDay(DayKey.adding(-12, to: today))
        read.backfill = true
        service.create(from: read, today: today)

        var water = HabitDraft()
        water.name = "Drink 8 glasses of water"
        water.emoji = "💧"
        water.color = .blue
        water.startDate = DayKey.startOfDay(DayKey.adding(-30, to: today))
        let waterHabit = service.create(from: water, today: today)
        for offset in 1...30 where offset % 4 != 0 {
            service.setResult(.success, for: waterHabit, on: DayKey.adding(-offset, to: today))
        }
        service.setNote("Felt great after the run", for: waterHabit, on: DayKey.adding(-2, to: today))

        var sugar = HabitDraft()
        sugar.name = "No sugar"
        sugar.emoji = "🍬"
        sugar.color = .pink
        sugar.kind = .stop
        sugar.countingMode = .strict
        sugar.startDate = DayKey.startOfDay(DayKey.adding(-20, to: today))
        let sugarHabit = service.create(from: sugar, today: today)
        service.setResult(.fail, for: sugarHabit, on: DayKey.adding(-6, to: today))
    }
}
#endif
