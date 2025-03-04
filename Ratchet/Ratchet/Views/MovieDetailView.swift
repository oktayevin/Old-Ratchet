import SwiftUI
import CoreData

struct MovieDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let movie: Movie
    
    @State private var showOptions = false
    @State private var watchProviders: [Provider] = []
    @State private var isLoadingProviders = false
    @State private var userRating: Int = 0
    @State private var errorMessage: String?
    @State private var currentWatchStatus: WatchStatus = .notInWatchlist
    @State private var showingCountrySelector = false

    private func getWatchStatus() -> WatchStatus {
        if movie.isWatched {
            return .watched
        } else if movie.isWatching {
            return .watching(progress: Double(movie.watchProgress))
        } else {
            return .notInWatchlist
        }
    }

    private func updateWatchStatus(_ status: WatchStatus) {
        switch status {
        case .watched:
            movie.isWatched = true
            movie.isWatching = false
            movie.watchProgress = 1.0
        case .watching(let progress):
            movie.isWatched = false
            movie.isWatching = true
            movie.watchProgress = Float(progress)
        case .notInWatchlist:
            movie.isWatched = false
            movie.isWatching = false
            movie.watchProgress = 0.0
        case .onHold:
            movie.isWatched = false
            movie.isWatching = false
            movie.watchProgress = movie.watchProgress  // Keep the existing progress
        case .dropped:
            movie.isWatched = false
            movie.isWatching = false
            movie.watchProgress = 0.0
        }
        
        do {
            try viewContext.save()
            currentWatchStatus = status  // Update the UI state
        } catch {
            print("Failed to update watch status: \(error)")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Backdrop
                
                if let backdropPath = movie.backdrop,
                   let url = URL(string: "https://image.tmdb.org/t/p/w1280\(backdropPath)") {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                    }
                    .frame(height: 200)
                    .clipped()
                }
                
                HStack(alignment: .top, spacing: 16) {
                    // Poster
                    if let posterPath = movie.poster,
                       let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.2))
                        }
                        .frame(width: 120, height: 180)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .offset(y: -20)
                        .padding(.leading)
                    }
                    
                    // Title and basic info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.title ?? "Unknown Title")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let releaseDate = movie.releaseDate {
                            Text(releaseDate, format: .dateTime.year())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let runtime = Int32(movie.runtime) ?? "" as? Int32{
                            Text("\(runtime) minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // User Rating
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= userRating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        updateRating(star)
                                    }
                            }
                        }
                        .padding(.top, 4)
                        
                        // Watch Status Button
                        WatchStatusButton(
                            status: currentWatchStatus,
                            accentColor: .blue
                        ) { newStatus in
                            updateWatchStatus(newStatus)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.trailing)
                    .padding(.top)
                }
                
                // Overview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overview")
                        .font(.headline)
                        .padding(.top)
                    
                    if let overview = movie.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No overview available")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding(.horizontal)
                
                // Watch Providers
                VStack(alignment: .leading, spacing: 12) {
                    Text("Where to Watch")
                        .font(.headline)
                        .padding(.top)
                    
                    if isLoadingProviders {
                        ProgressView()
                            .padding()
                    } else if watchProviders.isEmpty {
                        Text("No streaming information available")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(watchProviders) { provider in
                                    VStack {
                                        if let url = provider.logoURL {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                            } placeholder: {
                                                Color.gray.opacity(0.2)
                                            }
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(8)
                                        }
                                        
                                        Text(provider.providerName)
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 60)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
                
                WatchProvidersView(providers: watchProviders)
                    .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showOptions.toggle()
                }) {
                    Image(systemName: "ellipsis")
                }
                .confirmationDialog("Actions", isPresented: $showOptions, titleVisibility: .visible) {
                    Button("Add to Collection") { }
                    Button("Rate Movie") { }
                    Button("Remove from Watchlist", role: .destructive) { }
                    Button("Cancel", role: .cancel) { }
                }
            }
        }
        .onAppear {
            userRating = Int(movie.rating)
            loadWatchProviders()
        }
        .onReceive(NotificationCenter.default.publisher(for: .countryChanged)) { _ in
            loadWatchProviders()
        }
    }
    
    private func updateRating(_ rating: Int) {
        withAnimation {
            userRating = rating
            movie.rating = Float(rating)
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to update rating: \(error)")
            }
        }
    }
    
    private func loadWatchProviders() {
        guard movie.tmdbId > 0 else { return }
        
        isLoadingProviders = true
        
        Task {
            do {
                let response: WatchProviderResponse = try await TMDBClient.shared.fetch(
                    endpoint: .movieWatchProviders(id: Int(movie.tmdbId))
                )
                
                // Get providers for the user's country (US as default)
                if let usProviders = response.results["US"] {
                    var allProviders: [Provider] = []
                    
                    if let flatrate = usProviders.flatrate {
                        allProviders.append(contentsOf: flatrate)
                    }
                    
                    if let rent = usProviders.rent {
                        for provider in rent {
                            if !allProviders.contains(where: { $0.id == provider.id }) {
                                allProviders.append(provider)
                            }
                        }
                    }
                    
                    if let buy = usProviders.buy {
                        for provider in buy {
                            if !allProviders.contains(where: { $0.id == provider.id }) {
                                allProviders.append(provider)
                            }
                        }
                    }
                    
                    await MainActor.run {
                        self.watchProviders = allProviders
                        isLoadingProviders = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingProviders = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingProviders = false
                    errorMessage = "Failed to load watch providers. Please try again."
                }
                print("Failed to load watch providers: \(error)")
            }
        }
    }
}
