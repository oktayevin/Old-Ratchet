import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var settings = UserSettings.shared
    @State private var showingPreferences = false
    
    var body: some View {
        List {
            // Profile Header Section
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Guest User")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Sign in to sync your data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Settings Section
            Section {
                NavigationLink {
                    PreferencesView()
                } label: {
                    Label("Preferences", systemImage: "gear")
                }
                
                NavigationLink {
                    Text("Statistics View") // Placeholder for Statistics View
                } label: {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
            }
            
            // Data Management Section
            Section("Data Management") {
                Button {
                    // Add export functionality
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    // Add import functionality
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
                
                Button(role: .destructive) {
                    // Add clear data functionality
                } label: {
                    Label("Clear All Data", systemImage: "trash")
                }
            }
            
            // About Section
            Section("About") {
                NavigationLink {
                    Text("About View") // Placeholder for About View
                } label: {
                    Label("About Ratchet", systemImage: "info.circle")
                }
                
                Link(destination: URL(string: "https://www.themoviedb.org")!) {
                    HStack {
                        Label("Powered by TMDB", systemImage: "film")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Version Info
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Profile")
    }
}

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = UserSettings.shared
    @State private var showingCountrySelector = false
    
    var body: some View {
        List {
            Section("Region") {
                Button {
                    showingCountrySelector = true
                } label: {
                    HStack {
                        Label("Content Region", systemImage: "globe")
                        Spacer()
                        Text(UserSettings.countries[settings.selectedCountry] ?? "")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Appearance") {
                Toggle(isOn: .constant(false)) {
                    Label("Dark Mode", systemImage: "moon.fill")
                }
            }
            
            Section("Content") {
                Toggle(isOn: .constant(true)) {
                    Label("Adult Content", systemImage: "exclamationmark.triangle")
                }
            }
        }
        .navigationTitle("Preferences")
        .sheet(isPresented: $showingCountrySelector) {
            CountrySelectorView()
        }
    }
} 
