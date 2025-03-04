import Foundation

class UserSettings: ObservableObject {
    @Published var selectedCountry: String {
        didSet {
            UserDefaults.standard.set(selectedCountry, forKey: "selectedCountry")
        }
    }
    
    static let shared = UserSettings()
    
    init() {
        self.selectedCountry = UserDefaults.standard.string(forKey: "selectedCountry") ?? "US"
    }
    
    static let countries = [
        "US": "United States",
        "GB": "United Kingdom",
        "CA": "Canada",
        "AU": "Australia",
        "DE": "Germany",
        "FR": "France",
        "IT": "Italy",
        "ES": "Spain",
        "TR": "Turkey",
        // Add more countries as needed
    ]
} 