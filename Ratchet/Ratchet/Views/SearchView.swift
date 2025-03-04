import SwiftUI
import CoreData

struct SearchView: View {
    let viewContext: NSManagedObjectContext
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var selectedMediaType: MediaType = .movie
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search movies and TV shows", text: $searchText)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Media type selection
                Picker("Media Type", selection: $selectedMediaType) {
                    Text("Movies").tag(MediaType.movie)
                    Text("TV Shows").tag(MediaType.tv)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if isSearching {
                    ProgressView()
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !searchText.isEmpty && searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .font(.headline)
                        Text("Try different keywords or check your spelling")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !searchResults.isEmpty {
                    List {
                        ForEach(searchResults.filter { $0.mediaType == selectedMediaType }) { result in
                            Button {
                                addToLibrary(result)
                            } label: {
                                SearchResultRow(result: result)
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    // Initial state or empty search
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Search for content")
                            .font(.title2)
                        Text("Find movies and TV shows to add to your library")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                let response: SearchResponse = try await TMDBClient.shared.fetch(
                    endpoint: .searchMulti(query: searchText)
                )
                
                await MainActor.run {
                    // Filter out people and other non-movie/TV results
                    searchResults = response.results.filter { $0.mediaType == .movie || $0.mediaType == .tv }
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to search. Please try again."
                    isSearching = false
                }
            }
        }
    }
    
    private func addToLibrary(_ result: SearchResult) {
        Task {
            do {
                if result.mediaType == .movie {
                    let movieDetail: MovieDetail = try await TMDBClient.shared.fetch(
                        endpoint: .movieDetail(id: result.id)
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
                            dismiss()
                        } catch {
                            print("Failed to save movie: \(error)")
                        }
                    }
                } else if result.mediaType == .tv {
                    let tvDetail: TVShowDetail = try await TMDBClient.shared.fetch(
                        endpoint: .tvShowDetail(id: result.id)
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
                            dismiss()
                        } catch {
                            print("Failed to save TV show: \(error)")
                        }
                    }
                }
            } catch {
                print("Failed to fetch details: \(error)")
            }
        }
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack {
            if let url = result.posterURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                }
                .frame(width: 60, height: 90)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: result.mediaType == .movie ? "film" : "tv")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.displayTitle)
                    .font(.headline)
                
                if result.displayDate != "Unknown" {
                    Text(result.displayDate.prefix(4))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !result.overview.isEmpty {
                    Text(result.overview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                HStack {
                    Image(systemName: result.mediaType == .movie ? "film" : "tv")
                        .foregroundColor(.blue)
                    Text(result.mediaType == .movie ? "Movie" : "TV Show")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if let rating = result.voteAverage, rating > 0 {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
} 
