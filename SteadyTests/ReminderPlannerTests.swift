import Foundation
import Testing
@testable import Steady

struct ReminderPlannerTests {
    let today = 20261110

    private func input(kind: HabitKind = .start, start: Int = 20261101, minutes: Int = 9 * 60, resolved: Set<Int> = []) -> ReminderPlanner.Input {
        .init(habitID: UUID(), emoji: "📚", name: "Read", kind: kind, startDay: start, minutes: minutes, resolvedDays: resolved)
    }

    @Test func daysAheadStaysUnderLimit() {
        #expect(ReminderPlanner.daysAhead(habitCount: 0) == 0)
        #expect(ReminderPlanner.daysAhead(habitCount: 1) == 7)
        #expect(ReminderPlanner.daysAhead(habitCount: 8) == 7)
        #expect(ReminderPlanner.daysAhead(habitCount: 9) == 6)
        #expect(ReminderPlanner.daysAhead(habitCount: 20) == 3)
        #expect(ReminderPlanner.daysAhead(habitCount: 60) == 1)
        #expect(ReminderPlanner.daysAhead(habitCount: 100) == 1)
    }

    @Test func schedulesNextSevenDaysIncludingToday() {
        let plan = ReminderPlanner.plan([input()], today: today, minutesNow: 8 * 60)
        #expect(plan.map(\.day) == DayKey.days(from: today, through: DayKey.adding(6, to: today)))
        #expect(plan.allSatisfy { $0.hour == 9 && $0.minute == 0 })
    }

    @Test func skipsTodayWhenTimeHasPassed() {
        let plan = ReminderPlanner.plan([input()], today: today, minutesNow: 9 * 60)
        #expect(plan.first?.day == DayKey.adding(1, to: today))
        #expect(plan.count == 6)
    }

    @Test func skipsResolvedToday() {
        let plan = ReminderPlanner.plan([input(resolved: [today])], today: today, minutesNow: 0)
        #expect(!plan.map(\.day).contains(today))
        #expect(plan.count == 6)
    }

    @Test func respectsStartDate() {
        let plan = ReminderPlanner.plan([input(start: today)], today: today, minutesNow: 0)
        #expect(plan.first?.day == today)
    }

    @Test func totalNeverExceedsCap() {
        let habits = (0..<70).map { _ in input() }
        let plan = ReminderPlanner.plan(habits, today: today, minutesNow: 0)
        #expect(plan.count <= ReminderPlanner.maxPending)
        #expect(plan.allSatisfy { $0.day == today })
    }

    @Test func identifiersAreUnique() {
        let plan = ReminderPlanner.plan([input(), input(minutes: 20 * 60)], today: today, minutesNow: 0)
        #expect(Set(plan.map(\.identifier)).count == plan.count)
        #expect(plan.count == 14)
    }

    @Test func messages() {
        #expect(ReminderPlanner.message(for: input()) == "📚 Read")
        #expect(ReminderPlanner.message(for: input(kind: .stop)) == "📚 Still going strong today?")
    }

    @Test func soonestFirst() {
        let early = input(minutes: 7 * 60)
        let late = input(minutes: 21 * 60)
        let plan = ReminderPlanner.plan([late, early], today: today, minutesNow: 0)
        #expect(plan[0].hour == 7 && plan[1].hour == 21 && plan[0].day == today && plan[1].day == today)
    }
}
