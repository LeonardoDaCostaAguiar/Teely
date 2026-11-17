import SwiftUI

struct NeuSearchField: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
            TextField("search.placeholder", text: $text)
                .font(.manrope(.body))
                .foregroundStyle(Theme.primaryText)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(onSubmit)
                .accessibilityIdentifier("searchField")
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondaryText)
                }
                .accessibilityLabel(Text("search.clear"))
                .accessibilityIdentifier("clearSearchButton")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .neuInset(cornerRadius: 18, depth: 4)
    }
}
