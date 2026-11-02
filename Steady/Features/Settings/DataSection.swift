import SwiftUI
import UniformTypeIdentifiers

/// Export (JSON backup, CSV) and JSON import, each with a busy state.
struct DataSection: View {
    private enum Job: Hashable {
        case export(ExportFiles.Kind)
        case importing
    }

    @Environment(StorageController.self) private var storage
    @State private var busy: Job?
    @State private var shareItem: ShareItem?
    @State private var choosingFile = false
    @State private var pendingBackup: Backup?
    @State private var message: String?

    var body: some View {
        Section {
            row("Export backup (JSON)", systemImage: "square.and.arrow.up", job: .export(.json)) {
                export(.json)
            }
            row("Export spreadsheet (CSV)", systemImage: "tablecells", job: .export(.csv)) {
                export(.csv)
            }
            row("Import backup (JSON)", systemImage: "square.and.arrow.down", job: .importing) {
                choosingFile = true
            }
        } header: {
            Text("Data")
        }
        .sheet(item: $shareItem, onDismiss: { busy = nil }) { item in
            ActivityView(url: item.url)
                .presentationDetents([.medium, .large])
                .ignoresSafeArea()
                .onAppear { busy = nil }
        }
        .fileImporter(isPresented: $choosingFile, allowedContentTypes: [.json]) { result in
            read(result)
        }
        .confirmationDialog(
            "Import backup",
            isPresented: Binding(get: { pendingBackup != nil }, set: { if !$0 { pendingBackup = nil } }),
            titleVisibility: .visible,
            presenting: pendingBackup
        ) { backup in
            Button("Merge with my habits") { apply(backup, mode: .merge) }
            Button("Replace all my habits", role: .destructive) { apply(backup, mode: .replace) }
        } message: { backup in
            Text("This backup has \(backup.habits.count) habits. Merge keeps your habits and adds what's missing. Replace deletes your current habits first.")
        }
        .alert(
            "Import",
            isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private func row(_ title: LocalizedStringKey, systemImage: String, job: Job, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                if busy == job {
                    ProgressView()
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(busy != nil)
    }

    // MARK: Export

    private func export(_ kind: ExportFiles.Kind) {
        busy = .export(kind)
        Task {
            // Let the spinner render before the synchronous write.
            try? await Task.sleep(for: .milliseconds(50))
            do {
                let url = try ExportFiles.write(kind, context: storage.container.mainContext)
                shareItem = ShareItem(url: url)
            } catch {
                busy = nil
                message = error.localizedDescription
            }
        }
    }

    // MARK: Import

    private func read(_ result: Result<URL, Error>) {
        busy = .importing
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            pendingBackup = try Backup.decode(Data(contentsOf: url))
        } catch {
            message = error.localizedDescription
        }
        busy = nil
    }

    private func apply(_ backup: Backup, mode: Backup.ImportMode) {
        busy = .importing
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            do {
                try backup.apply(to: storage.container.mainContext, mode: mode)
                storage.service.refreshDerivedState()
                message = String(localized: "Import complete.")
            } catch {
                message = error.localizedDescription
            }
            busy = nil
        }
    }
}
