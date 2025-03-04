import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext: NSManagedObjectContext
    
    @FetchRequest(
        entity: Movie.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Movie.title, ascending: true)]
    ) private var movies: FetchedResults<Movie>
    
    @FetchRequest(
        entity: TVShow.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TVShow.name, ascending: true)]
    ) private var tvShows: FetchedResults<TVShow>
    
    var body: some View {
        List {
            // Movies Statistics
            Section("Movies") {
                StatCard(
                    title: "Total Movies",
                    value: "\(movies.count)",
                    icon: "film",
                    color: .blue
                )
                
                StatCard(
                    title: "Watched Movies",
                    value: "\(movies.filter { $0.isWatched }.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatCard(
                    title: "Average Rating",
                    value: String(format: "%.1f", calculateAverageMovieRating()),
                    icon: "star.fill",
                    color: .yellow
                )
            }
            
            // TV Shows Statistics
            Section("TV Shows") {
                StatCard(
                    title: "Total Shows",
                    value: "\(tvShows.count)",
                    icon: "tv",
                    color: .purple
                )
                
                StatCard(
                    title: "Watching",
                    value: "\(tvShows.filter { $0.isWatching }.count)",
                    icon: "play.circle",
                    color: .blue
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(tvShows.filter { $0.isWatched }.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatCard(
                    title: "On Hold",
                    value: "\(tvShows.filter { $0.watchStatus?.status == "onHold" }.count)",
                    icon: "pause.circle",
                    color: .orange
                )
                
                StatCard(
                    title: "Dropped",
                    value: "\(tvShows.filter { $0.watchStatus?.status == "dropped" }.count)",
                    icon: "xmark.circle",
                    color: .red
                )
                
                StatCard(
                    title: "Average Rating",
                    value: String(format: "%.1f", calculateAverageTVShowRating()),
                    icon: "star.fill",
                    color: .yellow
                )
            }
            
            // Watch Time Statistics
            Section("Watch Time") {
                StatCard(
                    title: "Total Movie Time",
                    value: formatWatchTime(calculateTotalMovieTime()),
                    icon: "clock",
                    color: .blue
                )
                
                StatCard(
                    title: "Total TV Time",
                    value: formatWatchTime(calculateTotalTVTime()),
                    icon: "clock",
                    color: .purple
                )
            }
        }
        .navigationTitle("Statistics")
    }
    
    private func calculateAverageMovieRating() -> Double {
        let ratedMovies = movies.filter { $0.rating > 0 }
        guard !ratedMovies.isEmpty else { return 0 }
        let totalRating = ratedMovies.reduce(0.0) { $0 + Double($1.rating) }
        return totalRating / Double(ratedMovies.count)
    }
    
    private func calculateAverageTVShowRating() -> Double {
        let ratedShows = tvShows.filter { $0.rating > 0 }
        guard !ratedShows.isEmpty else { return 0 }
        let totalRating = ratedShows.reduce(0.0) { $0 + Double($1.rating) }
        return totalRating / Double(ratedShows.count)
    }
    
    private func calculateTotalMovieTime() -> Int {
        movies.filter { $0.isWatched }.reduce(0) { $0 + Int($1.runtime) }
    }
    
    private func calculateTotalTVTime() -> Int {
        // Assuming average episode length of 40 minutes
        tvShows.reduce(0) { total, show in
            total + (Int(show.numberOfEpisodes) * 40)
        }
    }
    
    private func formatWatchTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        if hours > 24 {
            let days = hours / 24
            return "\(days) days"
        } else {
            return "\(hours) hours"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        StatisticsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 