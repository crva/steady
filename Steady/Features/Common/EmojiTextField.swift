import SwiftUI
import UIKit

/// A text field that opens the emoji keyboard and keeps a single grapheme.
struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeUIView(context: Context) -> EmojiUITextField {
        let field = EmojiUITextField()
        field.placeholder = placeholder
        field.textAlignment = .center
        field.font = .systemFont(ofSize: 28)
        field.tintColor = .label
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        field.setContentHuggingPriority(.required, for: .horizontal)
        return field
    }

    func updateUIView(_ field: EmojiUITextField, context: Context) {
        if field.text != text { field.text = text }
        field.placeholder = placeholder
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    @MainActor
    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) { self.text = text }

        @objc func editingChanged(_ field: UITextField) {
            // Keep only the most recently typed character.
            let value = field.text?.last.map(String.init) ?? ""
            if field.text != value { field.text = value }
            text.wrappedValue = value
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

final class EmojiUITextField: UITextField {
    override var textInputContextIdentifier: String? { "" }

    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" } ?? super.textInputMode
    }
}
