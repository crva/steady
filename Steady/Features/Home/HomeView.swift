import StoreKit
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(HabitService.self) private var service
    @Environment(StoreController.self) private var store
    @Environment(\.requestReview) private var requestReview
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.sortOrder)
    private var habits: [Habit]

    @State private var path: [Habit] = []
    @State private var showingNewHabit = false
    @State private var showingSettings = false
    @State private var noteTarget: NoteTarget?
    @State private var undo: UndoAction?

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Settings", systemImage: "gearshape") { showingSettings = true }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add habit", systemImage: "plus") { showingNewHabit = true }
                    }
                }
                .navigationDestination(for: Habit.self) { habit in
                    HabitDetailView(habit: habit)
                }
                .overlay(alignment: .bottom) {
                    if let undo {
                        UndoToast(action: undo) { self.undo = nil }
                            .padding(.bottom, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.snappy, value: undo?.id)
        }
        .sheet(isPresented: $showingNewHabit) {
            HabitFormView(habit: nil)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $noteTarget) { target in
            NoteEditor(target: target)
        }
        .onChange(of: longestCurrentStreak) { _, streak in
            // Ask for a rating once, after the first 7-day streak.
            guard streak >= 7, !appState.reviewRequested else { return }
            appState.reviewRequested = true
            requestReview()
        }
        #if DEBUG
        .task { openScreenshotScreen() }
        #endif
        .onChange(of: appState.pendingDeepLink, initial: true) { _, link in
            guard let link else { return }
            open(link)
            appState.pendingDeepLink = nil
        }
    }

    #if DEBUG
    /// For README screenshots: launch with `-screenshotScreen detail|form|settings`.
    private func openScreenshotScreen() {
        switch UserDefaults.standard.string(forKey: "screenshotScreen") {
        case "detail":
            let withNotes = habits.first { habit in (habit.entries ?? []).contains { !$0.note.isBlank } }
            path = (withNotes ?? habits.first).map { [$0] } ?? []
        case "form":
            showingNewHabit = true
        case "settings":
            showingSettings = true
        default:
            break
        }
    }
    #endif

    private func open(_ link: DeepLink) {
        showingNewHabit = false
        showingSettings = false
        noteTarget = nil
        switch link {
        case .home:
            path = []
        case .habit(let id):
            path = habits.first { $0.id == id }.map { [$0] } ?? []
        }
    }

    @ViewBuilder
    private var content: some View {
        if habits.isEmpty {
            emptyState
        } else {
            List {
                if appState.shouldShowSupporterCard(isSupporter: store.isSupporter) {
                    SupporterCard(
                        onLearnMore: {
                            appState.supporterCardSeen = true
                            showingSettings = true
                        },
                        onDismiss: { appState.supporterCardSeen = true }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .moveDisabled(true)
                }
                ForEach(habits) { habit in
                    HabitCard(
                        habit: habit,
                        today: appState.todayKey,
                        onToday: { tapToday(habit) },
                        onDayTap: { day in service.toggle(habit, on: day) },
                        onDayLongPress: { day in noteTarget = NoteTarget(habit: habit, day: day) }
                    )
                    .onTapGesture { path.append(habit) }
                    .accessibilityAction(named: Text("Open details")) { path.append(habit) }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .onMove { source, destination in
                    service.move(habits, from: source, to: destination)
                }
            }
            .listStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Button {
                showingNewHabit = true
            } label: {
                Label("Add your first habit", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .overlay(Capsule().strokeBorder(Color.primary, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var longestCurrentStreak: Int {
        habits.map { habit in
            HabitStats.compute(rules: habit.rules, entries: habit.entryRecords, today: appState.todayKey).currentStreak
        }
        .max() ?? 0
    }

    private var title: String {
        DayKey.startOfDay(appState.todayKey).formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private func tapToday(_ habit: Habit) {
        let today = appState.todayKey
        let wasSlipped = service.entry(of: habit, on: today)?.result == .fail
        service.toggle(habit, on: today)
        if habit.rules.defaultsToSuccess, !wasSlipped {
            let message = String(localized: "Slip logged")
            undo = UndoAction(message: message) {
                service.setResult(nil, for: habit, on: today)
            }
            AccessibilityNotification.Announcement(message).post()
        }
    }
}
