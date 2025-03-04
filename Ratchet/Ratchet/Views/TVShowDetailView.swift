import SwiftUI
import CoreData

struct TVShowDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let tvShow: TVShow
    @State private var selectedSeason: Int = 1
    @State private var episodes: [Episode] = []
    @State private var isLoadingEpisodes = false
    @State private var userRating: Int = 0
    @State private var watchProviders: [Provider] = []
    @State private var isLoadingProviders = false
    @State private var errorMessage: String?
    @State private var currentWatchStatus: WatchStatus = .notInWatchlist
    @State private var showingCountrySelector = false
    
    private func getWatchStatus() -> WatchStatus {
        if tvShow.isWatched {
            return .watched
        } else if tvShow.isWatching {
            return .watching(progress: Double(tvShow.watchProgress))
        } else {
            return .notInWatchlist
        }
    }
    
    private func updateWatchStatus(_ status: WatchStatus) {
        switch status {
        case .watched:
            tvShow.isWatched = true
            tvShow.isWatching = false
            tvShow.watchProgress = 1.0
        case .watching(let progress):
            // Calculate progress based on watched episodes
            let totalEpisodes = Double(tvShow.numberOfEpisodes)
            let watchedEpisodes = Double(tvShow.episodes?.compactMap { $0 as? TVEpisode }.filter { $0.isWatched }.count ?? 0)
            let calculatedProgress = watchedEpisodes / totalEpisodes
            
            tvShow.isWatched = false
            tvShow.isWatching = true
            tvShow.watchProgress = Float(calculatedProgress)
        case .notInWatchlist:
            tvShow.isWatched = false
            tvShow.isWatching = false
            tvShow.watchProgress = 0.0
        case .onHold:
            tvShow.isWatched = false
            tvShow.isWatching = false
            tvShow.watchProgress = tvShow.watchProgress  // Keep the existing progress
        case .dropped:
            tvShow.isWatched = false
            tvShow.isWatching = false
            tvShow.watchProgress = 0.0
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
                if let backdropPath = tvShow.backdrop, !backdropPath.isEmpty,
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
                    if let posterPath = tvShow.poster, !posterPath.isEmpty,
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
                        Text(tvShow.name ?? "Unknown Title")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let firstAirDate = tvShow.firstAirDate {
                            Text(firstAirDate, format: .dateTime.year())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("\(tvShow.numberOfSeasons) Seasons")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("\(tvShow.numberOfEpisodes) Episodes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let status = tvShow.status, !status.isEmpty {
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        // Overall TV Show Rating
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(tvShow.rating) ? "star.fill" : "star")
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
                    
                    if let overview = tvShow.overview, !overview.isEmpty {
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
                
                // Season selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Seasons")
                        .font(.headline)
                        .padding(.top)
                    
                    if tvShow.numberOfSeasons > 0 {
                        Picker("Season", selection: $selectedSeason) {
                            ForEach(1...Int(tvShow.numberOfSeasons), id: \.self) { season in
                                Text("Season \(season)").tag(season)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedSeason) { _ in
                            loadEpisodes(for: selectedSeason)
                        }
                    } else {
                        Text("No seasons available")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding(.horizontal)
                
                // Episodes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Episodes")
                        .font(.headline)
                        .padding(.top)
                    
                    if isLoadingEpisodes {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                            .italic()
                            .padding()
                    } else if episodes.isEmpty {
                        Text("No episodes available for this season")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                    } else {
                        ForEach(episodes) { episode in
                            EpisodeRow(
                                episode: episode,
                                tvShow: tvShow
                            )
                            .padding(.vertical, 4)
                            
                            if episode.id != episodes.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Watch Providers
                WatchProvidersView(providers: watchProviders)
                    .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Share functionality
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            userRating = Int(tvShow.rating)
            currentWatchStatus = getWatchStatus()  // Initialize currentWatchStatus
            loadWatchProviders()
            loadEpisodes(for: selectedSeason)
        }
        .onReceive(NotificationCenter.default.publisher(for: .countryChanged)) { _ in
            loadWatchProviders()
        }
    }
    
    private func updateRating(_ rating: Int) {
        withAnimation {
            userRating = rating
            tvShow.rating = Float(rating)
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to update rating: \(error)")
            }
        }
    }
    
    private func loadWatchProviders() {
        guard tvShow.tmdbId > 0 else { return }
        
        isLoadingProviders = true
        
        Task {
            do {
                let response: WatchProviderResponse = try await TMDBClient.shared.fetch(
                    endpoint: .tvShowWatchProviders(id: Int(tvShow.tmdbId))
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
                }
                print("Failed to load watch providers: \(error)")
            }
        }
    }
    
    private func loadEpisodes(for season: Int) {
        guard tvShow.tmdbId > 0 else { return }
        
        isLoadingEpisodes = true
        errorMessage = nil
        
        Task {
            do {
                let seasonDetail: SeasonDetail = try await TMDBClient.shared.fetch(
                    endpoint: .tvShowSeason(showId: Int(tvShow.tmdbId), seasonNumber: season)
                )
                
                await MainActor.run {
                    self.episodes = seasonDetail.episodes
                    isLoadingEpisodes = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load episodes. Please try again."
                    isLoadingEpisodes = false
                }
                print("Failed to load episodes: \(error)")
            }
        }
    }
}

struct EpisodeRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    let episode: Episode
    let tvShow: TVShow
    
    @State private var isWatched = false
    @State private var userRating = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                if let url = episode.stillURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                    }
                    .frame(width: 120, height: 68)
                    .cornerRadius(6)
                } else {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                        .frame(width: 120, height: 68)
                        .cornerRadius(6)
                        .overlay(
                            Image(systemName: "tv")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Episode \(episode.episodeNumber): \(episode.name)")
                        .font(.headline)
                    
                    if let airDate = episode.airDate, !airDate.isEmpty {
                        Text(airDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Find episode in Core Data
                    let storedEpisode = findStoredEpisode()
                    
                    HStack {
                        Button(action: {
                            toggleWatchedStatus()
                        }) {
                            HStack {
                                Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isWatched ? .green : .secondary)
                                Text(isWatched ? "Watched" : "Not watched")
                                    .font(.caption)
                                    .foregroundColor(isWatched ? .green : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Rating
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= userRating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                                .onTapGesture {
                                    updateRating(star)
                                }
                        }
                    }
                }
            }
            
            if !episode.overview.isEmpty {
                Text(episode.overview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .onAppear {
            loadEpisodeStatus()
        }
    }
    
    private func findStoredEpisode() -> TVEpisode? {
        let fetchRequest: NSFetchRequest<TVEpisode> = TVEpisode.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "show == %@ AND seasonNumber == %d AND episodeNumber == %d",
            tvShow, episode.seasonNumber, episode.episodeNumber
        )
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Failed to fetch episode: \(error)")
            return nil
        }
    }
    
    private func loadEpisodeStatus() {
        if let storedEpisode = findStoredEpisode() {
            isWatched = storedEpisode.isWatched
            userRating = Int(storedEpisode.rating)
        } else {
            // Create a new episode entry if it doesn't exist
            let newEpisode = TVEpisode(context: viewContext)
            newEpisode.id = Int64(episode.id)
            newEpisode.name = episode.name
            newEpisode.overview = episode.overview
            newEpisode.seasonNumber = Int16(episode.seasonNumber)
            newEpisode.episodeNumber = Int16(episode.episodeNumber)
            newEpisode.stillPath = episode.stillPath
            if let airDate = episode.airDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                newEpisode.airDate = formatter.date(from: airDate)
            }
            newEpisode.isWatched = false
            newEpisode.rating = 0
            newEpisode.show = tvShow
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to create episode: \(error)")
            }
        }
    }
    
    private func toggleWatchedStatus() {
        isWatched.toggle()
        
        let episode = findStoredEpisode() ?? TVEpisode(context: viewContext)
        episode.show = tvShow
        episode.seasonNumber = Int16(self.episode.seasonNumber)
        episode.episodeNumber = Int16(self.episode.episodeNumber)
        episode.isWatched = isWatched
        
        do {
            try viewContext.save()
            
            // Update the watch status of the TV show
            let status: WatchStatus
            let totalEpisodes = Double(tvShow.numberOfEpisodes)
            let watchedEpisodes = Double(tvShow.episodes?.compactMap { $0 as? TVEpisode }.filter { $0.isWatched }.count ?? 0)
            let progress = watchedEpisodes / totalEpisodes
            
            if progress >= 1.0 {
                status = .watched
            } else if progress > 0 {
                status = .watching(progress: progress)
            } else {
                status = .notInWatchlist
            }
            
            // Update the parent view's watch status
            tvShow.watchProgress = Float(progress)
            tvShow.isWatching = progress > 0 && progress < 1.0
            tvShow.isWatched = progress >= 1.0
            try viewContext.save()
        } catch {
            print("Failed to update episode status: \(error)")
        }
    }
    
    private func updateShowProgress() {
        let fetchRequest: NSFetchRequest<TVEpisode> = TVEpisode.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "show == %@", tvShow)
        
        do {
            let allEpisodes = try viewContext.fetch(fetchRequest)
            let watchedCount = allEpisodes.filter { $0.isWatched }.count
            let progress = Double(watchedCount) / Double(allEpisodes.count)
            
            if progress > 0 && progress < 1 {
                tvShow.isWatching = true
                tvShow.isWatched = false
                tvShow.watchProgress = Float(progress)
            } else if progress >= 1 {
                tvShow.isWatching = false
                tvShow.isWatched = true
                tvShow.watchProgress = 1.0
            } else {
                tvShow.isWatching = false
                tvShow.isWatched = false
                tvShow.watchProgress = 0.0
            }
            
            try viewContext.save()
        } catch {
            print("Failed to update show progress: \(error)")
        }
    }
    
    private func updateRating(_ rating: Int) {
        if let storedEpisode = findStoredEpisode() {
            storedEpisode.rating = Float(rating)
            userRating = rating
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to update episode rating: \(error)")
            }
        }
    }
}

