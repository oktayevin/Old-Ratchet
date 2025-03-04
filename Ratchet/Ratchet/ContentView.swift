//
//  ContentView.swift
//  Ratchet
//
//  Created by Oktay Evin on 2/25/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var isSearching = false
    @State private var searchText = ""
    
    @FetchRequest(
        entity: Movie.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Movie.title, ascending: true)]
    ) private var movies: FetchedResults<Movie>
    
    @FetchRequest(
        entity: TVShow.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TVShow.name, ascending: true)]
    ) private var tvShows: FetchedResults<TVShow>
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                contentForTab(0)
                    .navigationTitle("Movies")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isSearching = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isSearching = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tag(0)
            .tabItem {
                Label("Movies", systemImage: "film")
            }
            
            NavigationStack {
                contentForTab(1)
                    .navigationTitle("TV Shows")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isSearching = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isSearching = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tag(1)
            .tabItem {
                Label("TV Shows", systemImage: "tv")
            }
            
            NavigationStack {
                DiscoverView()
                    .navigationTitle("Discover")
            }
            .tag(2)
            .tabItem {
                Label("Discover", systemImage: "sparkles.tv")
            }
            
            NavigationStack {
                ProfileView()
                    .navigationTitle("Profile")
            }
            .tag(3)
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .sheet(isPresented: $isSearching) {
            SearchView(viewContext: viewContext)
        }
    }
    
    @ViewBuilder
    private func contentForTab(_ tab: Int) -> some View {
        if tab == 0 {
            // Movies tab
            if movies.isEmpty {
                emptyStateView(
                    title: "No Movies Yet",
                    message: "Your movie collection will appear here. Tap + to add movies to your collection.",
                    buttonText: "Add Movies",
                    action: { isSearching = true }
                )
            } else {
                List {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            movieRow(movie)
                        }
                    }
                    .onDelete(perform: deleteMovies)
                }
            }
        } else {
            // TV Shows tab
            if tvShows.isEmpty {
                emptyStateView(
                    title: "No TV Shows Yet",
                    message: "Your TV show collection will appear here. Tap + to add shows to your collection.",
                    buttonText: "Add TV Shows",
                    action: { isSearching = true }
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Now Playing Section
                        NowPlayingSection()
                            .padding(.top)
                        
                        // Your Shows Section with modern design
                        ForEach(WatchStatus.allCases, id: \.self) { status in
                            let filteredShows = tvShows.filter { show in
                                switch status {
                                case .watching:
                                    return show.isWatching
                                case .watched:
                                    return show.isWatched && !show.isWatching
                                case .onHold:
                                    return show.watchStatus?.status == "onHold"
                                case .dropped:
                                    return show.watchStatus?.status == "dropped"
                                case .notInWatchlist:
                                    return show.watchStatus == nil
                                }
                            }
                            
                            if !filteredShows.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(status.displayTitle)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(filteredShows) { show in
                                            NavigationLink(destination: TVShowDetailView(tvShow: show)) {
                                                HStack {
                                                    // Poster Image
                                                    if let posterPath = show.poster,
                                                       let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
                                                        AsyncImage(url: url) { image in
                                                            image
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                        } placeholder: {
                                                            Rectangle()
                                                                .foregroundColor(.gray.opacity(0.2))
                                                        }
                                                        .frame(width: 80, height: 120)
                                                        .cornerRadius(8)
                                                    } else {
                                                        Rectangle()
                                                            .foregroundColor(.gray.opacity(0.2))
                                                            .frame(width: 80, height: 120)
                                                            .cornerRadius(8)
                                                            .overlay(
                                                                Image(systemName: "tv")
                                                                    .foregroundColor(.gray)
                                                            )
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        Text(show.name ?? "Unknown Title")
                                                            .font(.headline)
                                                            .lineLimit(2)
                                                        
                                                        if let firstAirDate = show.firstAirDate {
                                                            Text(firstAirDate, format: .dateTime.year())
                                                                .font(.subheadline)
                                                                .foregroundColor(.secondary)
                                                        }
                                                        
                                                        HStack(spacing: 12) {
                                                            Text("\(show.numberOfSeasons) Seasons")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                            
                                                            if show.rating > 0 {
                                                                HStack(spacing: 2) {
                                                                    ForEach(1...Int(show.rating), id: \.self) { _ in
                                                                        Image(systemName: "star.fill")
                                                                            .foregroundColor(.yellow)
                                                                            .font(.caption)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(.leading, 8)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.gray)
                                                        .font(.caption)
                                                }
                                                .padding()
                                                .background(Color(.systemBackground))
                                                .cornerRadius(12)
                                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.bottom)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
    }
    
    private func deleteMovies(offsets: IndexSet) {
        withAnimation {
            offsets.map { movies[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete movies: \(error)")
            }
        }
    }
    
    private func deleteTVShows(offsets: IndexSet) {
        withAnimation {
            offsets.map { tvShows[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete TV shows: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private func movieRow(_ movie: Movie) -> some View {
        HStack {
            if let posterPath = movie.poster, !posterPath.isEmpty,
               let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
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
                        Image(systemName: "film")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title ?? "Unknown Title")
                    .font(.headline)
                
                if let releaseDate = movie.releaseDate {
                    Text(releaseDate, format: .dateTime.year())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if movie.isWatched {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Watched")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                        Text("Not watched")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if movie.rating > 0 {
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(1...Int(movie.rating), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func emptyStateView(title: String, message: String, buttonText: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: selectedTab == 0 ? "film" : "tv")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(buttonText, action: action)
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
        .padding()
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

extension WatchStatus: CaseIterable {
    static var allCases: [WatchStatus] {
        [.watching(progress: 0), .watched, .onHold, .dropped, .notInWatchlist]
    }
    
    var displayTitle: String {
        switch self {
        case .watching:
            return "Watching"
        case .watched:
            return "Completed"
        case .onHold:
            return "On Hold"
        case .dropped:
            return "Dropped"
        case .notInWatchlist:
            return "Plan to Watch"
        }
    }
    
    static func == (lhs: WatchStatus, rhs: WatchStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notInWatchlist, .notInWatchlist),
             (.watched, .watched),
             (.onHold, .onHold),
             (.dropped, .dropped):
            return true
        case (.watching, .watching):
            return true
        default:
            return false
        }
    }
}

extension WatchStatus: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .notInWatchlist:
            hasher.combine(0)
        case .watching(let progress):
            hasher.combine(1)
            hasher.combine(progress)
        case .watched:
            hasher.combine(2)
        case .onHold:
            hasher.combine(3)
        case .dropped:
            hasher.combine(4)
        }
    }
}
