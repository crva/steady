import SwiftUI
import UniformTypeIdentifiers

/// Export (JSON backup, CSV) and JSON import.
struct DataSection: View {
    @Environment(StorageController.self) private var storage
    @State private var files: ExportFiles.Files?
    @State private var importing = false
    @State private var pendingBackup: Backup?
    @State private var message: String?

    var body: some View {
        Section {
            if let files {
                ShareLink(item: files.json) {
                    Label("Export backup (JSON)", systemImage: "square.and.arrow.up")
                }
                ShareLink(item: files.csv) {
                    Label("Export spreadsheet (CSV)", systemImage: "tablecells")
                }
            }
            Button {
                importing = true
            } label: {
                Label("Import backup (JSON)", systemImage: "square.and.arrow.down")
            }
        } header: {
            Text("Data")
        }
        .task(id: storage.generation) {
            files = try? ExportFiles.write(context: storage.container.mainContext)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
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

    private func read(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            pendingBackup = try Backup.decode(Data(contentsOf: url))
        } catch {
            message = error.localizedDescription
        }
    }

    private func apply(_ backup: Backup, mode: Backup.ImportMode) {
        do {
            try backup.apply(to: storage.container.mainContext, mode: mode)
            storage.service.refreshDerivedState()
            files = try? ExportFiles.write(context: storage.container.mainContext)
            message = String(localized: "Import complete.")
        } catch {
            message = error.localizedDescription
        }
    }
}
