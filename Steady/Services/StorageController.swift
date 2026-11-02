import CoreData
import Foundation
import Observation
import SwiftData

/// Owns the active SwiftData container and moves data between local and iCloud stores.
@MainActor
@Observable
final class StorageController {
    enum SwitchError: LocalizedError {
        case iCloudUnavailable
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .iCloudUnavailable:
                String(localized: "iCloud isn't available. Sign in to iCloud in the Settings app, then try again. Your habits stay on this iPhone for now.")
            case .verificationFailed:
                String(localized: "Your habits couldn't be copied completely, so nothing was changed.")
            }
        }
    }

    private enum Keys {
        static let pendingDeletion = "storesPendingDeletion"
    }

    private(set) var container: ModelContainer
    private(set) var service: HabitService
    private(set) var activeMode: StorageMode
    /// Changes whenever the container is swapped, to rebuild the view tree.
    private(set) var generation = UUID()
    private(set) var isMigrating = false

    private let appState: AppState
    private let defaults: UserDefaults
    private var remoteChangeTask: Task<Void, Never>?

    init(appState: AppState, defaults: UserDefaults = .standard) {
        self.appState = appState
        self.defaults = defaults

        var mode = appState.storageMode ?? .local
        let pending = Self.pendingDeletion(in: defaults).subtracting([mode])
        for stale in pending { ModelContainerFactory.deleteStoreFiles(for: stale) }
        Self.setPendingDeletion([], in: defaults)

        let container: ModelContainer
        do {
            container = try ModelContainerFactory.make(for: mode)
        } catch {
            // The iCloud store couldn't open; fall back to local rather than crash.
            assertionFailure("Store failed to open: \(error)")
            mode = .local
            appState.storageMode = appState.storageMode == nil ? nil : .local
            do {
                container = try ModelContainerFactory.make(for: .local)
            } catch {
                fatalError("Could not open the local store: \(error)")
            }
        }
        self.container = container
        self.activeMode = mode
        self.service = HabitService(context: container.mainContext)
        observeRemoteChanges()
    }

    /// Whether iCloud can be offered at all (feature flag).
    var isICloudOffered: Bool { FeatureFlags.iCloudSync }

    var isICloudAvailable: Bool {
        guard isICloudOffered else { return false }
        #if DEBUG
        if CommandLine.arguments.contains("-forceICloudAvailable") { return true }
        #endif
        return FileManager.default.ubiquityIdentityToken != nil
    }

    /// Dedupe and refresh derived state (widgets, reminders). Call on launch,
    /// foreground and day change.
    func refresh() {
        let context = container.mainContext
        if Deduplicator.run(in: context) { try? context.save() }
        service.refreshDerivedState()
    }

    /// With iCloud turned off, moves any data from an earlier iCloud session back to local.
    func moveOffICloudIfDisabled() async {
        guard !isICloudOffered, activeMode == .iCloud else { return }
        try? await switchTo(.local)
    }

    /// Copies every habit and entry into the other store, verifies, then switches.
    /// The old store's files are deleted on next launch, once nothing holds them open.
    func switchTo(_ mode: StorageMode) async throws {
        guard mode != activeMode else {
            appState.storageMode = mode
            return
        }
        if mode == .iCloud, !isICloudAvailable { throw SwitchError.iCloudUnavailable }

        isMigrating = true
        defer { isMigrating = false }
        await Task.yield()

        let source = container.mainContext
        try? source.save()
        let backup = Backup(context: source)

        let destination = try ModelContainerFactory.make(for: mode)
        let target = destination.mainContext
        var pending = Self.pendingDeletion(in: defaults)
        if pending.contains(mode) {
            // Leftovers from before an earlier switch away; the source is authoritative.
            try backup.apply(to: target, mode: .replace)
            pending.remove(mode)
        } else {
            try backup.apply(to: target, mode: .merge)
        }
        guard backup.isContained(in: target) else { throw SwitchError.verificationFailed }

        pending.insert(activeMode)
        Self.setPendingDeletion(pending, in: defaults)

        container = destination
        service = HabitService(context: target)
        activeMode = mode
        appState.storageMode = mode
        generation = UUID()
        service.refreshDerivedState()
    }

    // MARK: - Private

    private func observeRemoteChanges() {
        remoteChangeTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .NSPersistentStoreRemoteChange) {
                try? await Task.sleep(for: .seconds(1))
                self?.refresh()
            }
        }
    }

    private static func pendingDeletion(in defaults: UserDefaults) -> Set<StorageMode> {
        Set((defaults.stringArray(forKey: Keys.pendingDeletion) ?? []).compactMap(StorageMode.init(rawValue:)))
    }

    private static func setPendingDeletion(_ modes: Set<StorageMode>, in defaults: UserDefaults) {
        defaults.set(modes.map(\.rawValue), forKey: Keys.pendingDeletion)
    }
}
