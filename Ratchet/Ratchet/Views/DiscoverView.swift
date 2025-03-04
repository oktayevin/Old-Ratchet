import SwiftUI
import CoreData

struct DiscoverView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var trendingMovies: [MovieResult] = []
    @State private var trendingTVShows: [TVShowResult] = []
    @State private var isLoadingMovies = false
    @State private var isLoadingTVShows = false
    @State private var selectedItem: MediaType = .movie
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Content Type", selection: $selectedItem) {
                    Text("Movies").tag(MediaType.movie)
                    Text("TV Shows").tag(MediaType.tv)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if selectedItem == .movie {
                    if isLoadingMovies {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if trendingMovies.isEmpty {
                        Text("No trending movies available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Trending Movies
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trending Movies")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(trendingMovies) { movie in
                                        TrendingMovieCard(movie: movie, viewContext: viewContext)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                } else {
                    if isLoadingTVShows {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if trendingTVShows.isEmpty {
                        Text("No trending TV shows available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Trending TV Shows
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trending TV Shows")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(trendingTVShows) { show in
                                        TrendingTVShowCard(show: show, viewContext: viewContext)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if trendingMovies.isEmpty && !isLoadingMovies {
                loadTrendingMovies()
            }
            
            if trendingTVShows.isEmpty && !isLoadingTVShows {
                loadTrendingTVShows()
            }
        }
    }
    
    private func loadTrendingMovies() {
        isLoadingMovies = true
        errorMessage = nil
        
        Task {
            do {
                let response: MovieResponse = try await TMDBClient.shared.fetch(
                    endpoint: .trendingMovies
                )
                
                await MainActor.run {
                    self.trendingMovies = response.results
                    isLoadingMovies = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load trending movies"
                    isLoadingMovies = false
                }
                print("Failed to load trending movies: \(error)")
            }
        }
    }
    
    private func loadTrendingTVShows() {
        isLoadingTVShows = true
        errorMessage = nil
        
        Task {
            do {
                let response: TVShowResponse = try await TMDBClient.shared.fetch(
                    endpoint: .trendingTVShows
                )
                
                await MainActor.run {
                    self.trendingTVShows = response.results
                    isLoadingTVShows = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load trending TV shows"
                    isLoadingTVShows = false
                }
                print("Failed to load trending TV shows: \(error)")
            }
        }
    }
}

struct TrendingMovieCard: View {
    let movie: MovieResult
    let viewContext: NSManagedObjectContext
    
    var body: some View {
        VStack(alignment: .leading) {
            if let url = movie.posterURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                }
                .frame(width: 150, height: 225)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
                    .frame(width: 150, height: 225)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "film")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(movie.title)
                .font(.headline)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            if let releaseDate = movie.releaseDate, !releaseDate.isEmpty {
                Text(releaseDate.prefix(4))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button("Add to Library") {
                addMovieToLibrary()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(width: 150)
    }
    
    private func addMovieToLibrary() {
        Task {
            do {
                let movieDetail: MovieDetail = try await TMDBClient.shared.fetch(
                    endpoint: .movieDetail(id: movie.id)
                )
                
                await MainActor.run {
                    let newMovie = Movie(context: viewContext)
                    newMovie.id = Int64(movieDetail.id)
                    newMovie.tmdbId = Int64(movieDetail.id)
                    newMovie.title = movieDetail.title
                    newMovie.overview = movieDetail.overview
                    newMovie.poster = movieDetail.posterPath
                    newMovie.backdrop = movieDetail.backdropPath
                    if let releaseDate = movieDetail.releaseDate {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        newMovie.releaseDate = formatter.date(from: releaseDate)
                    }
                    newMovie.runtime = Int32(movieDetail.runtime ?? 0)
                    newMovie.isWatched = false
                    newMovie.rating = 0
                    
                    do {
                        try viewContext.save()
                    } catch {
                        print("Failed to save movie: \(error)")
                    }
                }
            } catch {
                print("Failed to fetch movie details: \(error)")
            }
        }
    }
}

struct TrendingTVShowCard: View {
    let show: TVShowResult
    let viewContext: NSManagedObjectContext
    
    var body: some View {
        VStack(alignment: .leading) {
            if let url = show.posterURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                }
                .frame(width: 150, height: 225)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
                    .frame(width: 150, height: 225)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "tv")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(show.name)
                .font(.headline)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            if let firstAirDate = show.firstAirDate, !firstAirDate.isEmpty {
                Text(firstAirDate.prefix(4))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button("Add to Library") {
                addTVShowToLibrary()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(width: 150)
    }
    
    private func addTVShowToLibrary() {
        Task {
            do {
                let tvDetail: TVShowDetail = try await TMDBClient.shared.fetch(
                    endpoint: .tvShowDetail(id: show.id)
                )
                
                await MainActor.run {
                    let newShow = TVShow(context: viewContext)
                    newShow.id = Int64(tvDetail.id)
                    newShow.tmdbId = Int64(tvDetail.id)
                    newShow.name = tvDetail.name
                    newShow.overview = tvDetail.overview
                    newShow.poster = tvDetail.posterPath
                    newShow.backdrop = tvDetail.backdropPath
                    if let firstAirDate = tvDetail.firstAirDate {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        newShow.firstAirDate = formatter.date(from: firstAirDate)
                    }
                    newShow.numberOfSeasons = Int16(tvDetail.numberOfSeasons)
                    newShow.numberOfEpisodes = Int16(tvDetail.numberOfEpisodes)
                    newShow.status = tvDetail.status
                    newShow.rating = 0
                    
                    do {
                        try viewContext.save()
                    } catch {
                        print("Failed to save TV show: \(error)")
                    }
                }
            } catch {
                print("Failed to fetch TV show details: \(error)")
            }
        }
    }
} 