import SwiftUI

struct MovieActionsView: View {
    let movie: Movie
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Handle adding to collection
                dismiss()
            }) {
                Label("Add to Collection", systemImage: "folder")
            }
            .padding()

            Button(action: {
                // Handle rating
                dismiss()
            }) {
                Label("Rate Movie", systemImage: "star")
            }
            .padding()

            Button(action: {
                // Handle removal
                dismiss()
            }) {
                Label("Remove", systemImage: "trash")
                    .foregroundColor(.red)
            }
            .padding()

            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .padding()
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(maxWidth: 300)
    }
}
