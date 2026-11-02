import SwiftUI

struct ColorSwatches: View {
    @Binding var selection: PaletteColor
    var colors: [PaletteColor]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(colors) { color in
                Button {
                    selection = color
                } label: {
                    Circle()
                        .fill(color.color)
                        .frame(width: 30, height: 30)
                        .padding(4)
                        .overlay {
                            if selection == color {
                                Circle().strokeBorder(Color.primary, lineWidth: 2)
                            }
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(color.localizedName)
                .accessibilityAddTraits(selection == color ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}
