import SwiftUI
import CoreData

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
                            Text(movieDetail.genres.map { $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions {
                    Button {
                        markMovieAsWatched()
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
            loadMovie()
        }
    }
    
    private func markMovieAsWatched() {
        guard let movie = movie else { return }
        
        // Update movie status
        let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tmdbId == %d", movie.id)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let movie = results.first {
                movie.isWatched = true
                movie.isWatching = false
                movie.watchProgress = 1.0
                try viewContext.save()
            }
        } catch {
            print("Failed to update movie status: \(error)")
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
            movie.status = movieDetail.status
            
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
}