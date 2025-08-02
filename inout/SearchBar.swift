import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    private var backgroundColor: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(backgroundColor)
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
        }
    }
}
