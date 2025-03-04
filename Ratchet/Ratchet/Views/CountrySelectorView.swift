import SwiftUI

struct CountrySelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = UserSettings.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(UserSettings.countries.sorted(by: { $0.value < $1.value }), id: \.key) { code, name in
                    Button {
                        settings.selectedCountry = code
                        // Trigger watch providers reload
                        NotificationCenter.default.post(name: .countryChanged, object: nil)
                        dismiss()
                    } label: {
                        HStack {
                            Text(name)
                            Spacer()
                            if settings.selectedCountry == code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Add this extension to handle country change notifications
extension Notification.Name {
    static let countryChanged = Notification.Name("countryChanged")
} 