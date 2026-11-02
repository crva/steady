import SwiftUI

/// Identifies the habit/day whose note is being edited.
struct NoteTarget: Identifiable {
    let habit: Habit
    let day: Int
    var id: String { "\(habit.id)-\(day)" }
}

struct NoteEditor: View {
    let target: NoteTarget
    @Environment(HabitService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            TextField("Note", text: $text, axis: .vertical)
                .lineLimit(4...12)
                .focused($focused)
                .padding(16)
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle(HabitText.shortDate(target.day))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            service.setNote(text, for: target.habit, on: target.day)
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium])
        .onAppear {
            text = service.entry(of: target.habit, on: target.day)?.note ?? ""
            focused = true
        }
    }
}
