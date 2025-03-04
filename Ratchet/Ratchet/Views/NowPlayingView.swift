import SwiftUI
import CoreData

struct NowPlayingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Use @FetchRequest with a static fetch request
    @FetchRequest(
        entity: WatchStatusEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchStatusEntity.lastWatchedDate, ascending: false)],
        predicate: NSPredicate(format: "status == %@", "watching")
    ) private var watchStatuses: FetchedResults<WatchStatusEntity>
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Now Playing")) {
                    ForEach(watchStatuses) { status in
                        if let mediaType = status.mediaType {
                            if mediaType == "movie" {
                                MovieNowPlayingRow(mediaId: Int(status.mediaId))
                            } else if mediaType == "tv" {
                                TVShowNowPlayingRow(
                                    tvShow: status.tvShow,
                                    mediaId: Int(status.mediaId),
                                    currentEpisode: EpisodeProgress(
                                        seasonNumber: Int(status.currentSeasonNumber),
                                        episodeNumber: Int(status.currentEpisodeNumber)
                                    )
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Now Playing")
        }
    }
}

struct MovieNowPlayingRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    let mediaId: Int
    @State private var movie: MovieDetail?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let movieDetail = movie {
                let movie = createOrUpdateMovie(from: movieDetail)
                NavigationLink(destination: MovieDetailView(movie: movie)) {
                    HStack {
                        AsyncImage(url: movieDetail.posterURL) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(movieDetail.title)
                                .font(.headline)
                            Text(movieDetail.genresString)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else if isLoading {
                ProgressView()
            }
        }
        .onAppear {
            loadMovie()
        }
    }
    
    private func createOrUpdateMovie(from movieDetail: MovieDetail) -> Movie {
        let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tmdbId == %d", movieDetail.id)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let movie = results.first ?? Movie(context: viewContext)
            
            // Update movie properties
            movie.tmdbId = Int64(movieDetail.id)
            movie.title = movieDetail.title
            movie.overview = movieDetail.overview
            movie.poster = movieDetail.posterPath
            movie.backdrop = movieDetail.backdropPath
            movie.releaseDate = movieDetail.releaseDate.flatMap { date -> Date? in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.date(from: date)
            }
            movie.runtime = Int32(movieDetail.runtime ?? 0)
            
            try viewContext.save()
            return movie
        } catch {
            print("Failed to create/update movie: \(error)")
            let movie = Movie(context: viewContext)
            movie.tmdbId = Int64(movieDetail.id)
            movie.title = movieDetail.title
            return movie
        }
    }
    
    private func loadMovie() {
        isLoading = true
        Task {
            do {
                movie = try await TMDBClient.shared.fetch(endpoint: .movieDetail(id: mediaId))
                isLoading = false
            } catch {
                print("Error loading movie: \(error)")
                isLoading = false
            }
        }
    }
}

struct TVShowNowPlayingRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    let tvShow: TVShow?
    let mediaId: Int
    let currentEpisode: EpisodeProgress
    @State private var show: TVShowDetail?
    @State private var episode: Episode?
    @State private var isLoading = true
    @State private var nextEpisode: EpisodeProgress?
    
    var body: some View {
        Group {
            if let showDetail = show {
                let tvShow = createOrUpdateTVShow(from: showDetail)
                NavigationLink(destination: TVShowDetailView(tvShow: tvShow)) {
                    HStack {
                        AsyncImage(url: showDetail.posterURL) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(showDetail.name)
                                .font(.headline)
                            if let episode = episode {
                                Text("S\(episode.seasonNumber)E\(episode.episodeNumber) - \(episode.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text(showDetail.genres.map { $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions {
                    Button {
                        markEpisodeAsWatched()
                    } label: {
                        Label("Mark as Watched", systemImage: "checkmark")
                    }
                    .tint(.green)
                }
            } else if isLoading {
                ProgressView()
            }
        }
        .onAppear {
            loadTVShow()
        }
    }
    
    private func markEpisodeAsWatched() {
        guard let tvShow = tvShow,
              let episodes = tvShow.episodes?.allObjects as? [TVEpisode] else { return }
        
        // Find current episode
        if let currentEpisode = episodes.first(where: { 
            Int($0.seasonNumber) == currentEpisode.seasonNumber && 
            Int($0.episodeNumber) == currentEpisode.episodeNumber 
        }) {
            // Mark current episode as watched
            currentEpisode.isWatched = true
            
            // Find next unwatched episode
            let sortedEpisodes = episodes.sorted { 
                ($0.seasonNumber, $0.episodeNumber) < ($1.seasonNumber, $1.episodeNumber) 
            }
            
            if let nextUnwatched = sortedEpisodes.first(where: { !$0.isWatched }) {
                // Update watch status with next episode
                if let watchStatus = tvShow.watchStatus {
                    watchStatus.currentSeasonNumber = nextUnwatched.seasonNumber
                    watchStatus.currentEpisodeNumber = nextUnwatched.episodeNumber
                    watchStatus.lastWatchedDate = Date()
                }
            } else {
                // No more unwatched episodes, mark show as completed
                if let watchStatus = tvShow.watchStatus {
                    watchStatus.status = "completed"
                }
                tvShow.isWatched = true
                tvShow.isWatching = false
            }
            
            // Save changes
            do {
                try viewContext.save()
            } catch {
                print("Failed to update episode status: \(error)")
            }
        }
    }
    
    private func loadTVShow() {
        isLoading = true
        Task {
            do {
                show = try await TMDBClient.shared.fetch(endpoint: .tvShowDetail(id: mediaId))
                let seasonNumber = currentEpisode.seasonNumber
                let episodeNumber = currentEpisode.episodeNumber
                
                if seasonNumber > 0 && episodeNumber > 0 {
                    let seasonDetail: SeasonDetail = try await TMDBClient.shared.fetch(
                        endpoint: .tvShowSeason(showId: mediaId, seasonNumber: seasonNumber)
                    )
                    episode = seasonDetail.episodes.first { $0.episodeNumber == episodeNumber }
                }
                isLoading = false
            } catch {
                print("Error loading TV show: \(error)")
                isLoading = false
            }
        }
    }
    
    private func createOrUpdateTVShow(from showDetail: TVShowDetail) -> TVShow {
        let fetchRequest: NSFetchRequest<TVShow> = TVShow.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tmdbId == %d", showDetail.id)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let tvShow = results.first ?? TVShow(context: viewContext)
            
            // Update TV show properties
            tvShow.tmdbId = Int64(showDetail.id)
            tvShow.name = showDetail.name
            tvShow.overview = showDetail.overview
            tvShow.poster = showDetail.posterPath
            tvShow.backdrop = showDetail.backdropPath
            tvShow.firstAirDate = showDetail.firstAirDate.flatMap { date -> Date? in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.date(from: date)
            }
            tvShow.numberOfSeasons = Int16(showDetail.numberOfSeasons)
            tvShow.numberOfEpisodes = Int16(showDetail.numberOfEpisodes)
            tvShow.status = showDetail.status
            
            try viewContext.save()
            return tvShow
        } catch {
            print("Failed to create/update TV show: \(error)")
            let tvShow = TVShow(context: viewContext)
            tvShow.tmdbId = Int64(showDetail.id)
            tvShow.name = showDetail.name
            return tvShow
        }
    }
}

struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
    }
}

struct NowPlayingSection: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: TVShow.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TVShow.name, ascending: true)],
        predicate: NSPredicate(format: "isWatching == YES")
    ) private var watchingShows: FetchedResults<TVShow>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !watchingShows.isEmpty {
                Text("Continue Watching")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(watchingShows) { show in
                            CurrentlyWatchingCard(tvShow: show)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct CurrentlyWatchingCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    let tvShow: TVShow
    @State private var currentEpisode: Episode?
    @State private var isLoading = true
    
    var body: some View {
        NavigationLink(destination: TVShowDetailView(tvShow: tvShow)) {
            VStack(alignment: .leading, spacing: 8) {
                // Episode Still Image or Show Poster
                if let currentEpisode = currentEpisode,
                   let stillURL = currentEpisode.stillURL {
                    AsyncImage(url: stillURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 220, height: 124)
                    .cornerRadius(8)
                } else if let posterPath = tvShow.poster,
                          let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 220, height: 124)
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tvShow.name ?? "Unknown Show")
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let currentEpisode = currentEpisode {
                        Text("S\(currentEpisode.seasonNumber)E\(currentEpisode.episodeNumber) - \(currentEpisode.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 3)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * CGFloat(tvShow.watchProgress), height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                .frame(width: 220)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadCurrentEpisode()
        }
    }
    
    private func loadCurrentEpisode() {
        guard let watchStatus = tvShow.watchStatus else { return }
        
        Task {
            do {
                let seasonDetail: SeasonDetail = try await TMDBClient.shared.fetch(
                    endpoint: .tvShowSeason(
                        showId: Int(tvShow.tmdbId),
                        seasonNumber: Int(watchStatus.currentSeasonNumber)
                    )
                )
                
                await MainActor.run {
                    currentEpisode = seasonDetail.episodes.first {
                        $0.episodeNumber == Int(watchStatus.currentEpisodeNumber)
                    }
                    isLoading = false
                }
            } catch {
                print("Error loading current episode: \(error)")
                isLoading = false
            }
        }
    }
}

#Preview {
    NowPlayingSection()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}