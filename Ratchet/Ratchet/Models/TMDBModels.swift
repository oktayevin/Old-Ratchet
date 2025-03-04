import Foundation

// MARK: - Movie Models
struct MovieResponse: Decodable {
    let page: Int
    let results: [MovieResult]
    let totalPages: Int
    let totalResults: Int
}

struct MovieResult: Identifiable, Decodable {
    let id: Int
    let title: String
    let posterPath: String?
    let backdropPath: String?
    let overview: String
    let releaseDate: String?
    let voteAverage: Double
    
    var posterURL: URL? {
        posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }
    
    var backdropURL: URL? {
        backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w1280\($0)") }
    }
}

struct MovieDetail: Decodable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let runtime: Int?
    let voteAverage: Double
    let genres: [Genre]
    
    var posterURL: URL? {
        posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }
    
    var backdropURL: URL? {
        backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w1280\($0)") }
    }
}

// MARK: - TV Show Models
struct TVShowResponse: Decodable {
    let page: Int
    let results: [TVShowResult]
    let totalPages: Int
    let totalResults: Int
}

struct TVShowResult: Identifiable, Decodable {
    let id: Int
    let name: String
    let posterPath: String?
    let backdropPath: String?
    let overview: String
    let firstAirDate: String?
    let voteAverage: Double
    
    var posterURL: URL? {
        posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }
    
    var backdropURL: URL? {
        backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w1280\($0)") }
    }
}

struct TVShowDetail: Decodable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let numberOfSeasons: Int
    let numberOfEpisodes: Int
    let voteAverage: Double
    let status: String
    let genres: [Genre]
    let seasons: [Season]
    
    var posterURL: URL? {
        posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }
    
    var backdropURL: URL? {
        backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w1280\($0)") }
    }
}

struct Season: Identifiable, Decodable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int
    let posterPath: String?
    
    var posterURL: URL? {
        posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }
}

struct SeasonDetail: Decodable {
    let id: Int
    let seasonNumber: Int
    let episodes: [Episode]
}

struct Episode: Identifiable, Decodable {
    let id: Int
    let name: String
    let overview: String
    let episodeNumber: Int
    let seasonNumber: Int
    let stillPath: String?
    let airDate: String?
    
    var stillURL: URL? {
        stillPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }
}

// MARK: - Common Models
struct Genre: Identifiable, Decodable {
    let id: Int
    let name: String
}

// MARK: - Search Models
struct SearchResponse: Decodable {
    let page: Int
    let results: [SearchResult]
    let totalPages: Int
    let totalResults: Int
}

struct SearchResult: Identifiable, Decodable {
    let id: Int
    let mediaType: MediaType
    
    // Movie properties
    let title: String?
    let releaseDate: String?
    
    // TV properties
    let name: String?
    let firstAirDate: String?
    
    // Common properties
    let posterPath: String?
    let backdropPath: String?
    let overview: String
    let voteAverage: Double?
    
    var displayTitle: String {
        if mediaType == .movie {
            return title ?? "Unknown"
        } else {
            return name ?? "Unknown"
        }
    }
    
    var displayDate: String {
        if mediaType == .movie {
            return releaseDate ?? "Unknown"
        } else {
            return firstAirDate ?? "Unknown"
        }
    }
    
    var posterURL: URL? {
        posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }
    
    var backdropURL: URL? {
        backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w1280\($0)") }
    }
}

enum MediaType: String, Decodable {
    case movie
    case tv
    case person
}

// MARK: - Watch Provider Models
struct WatchProviderResponse: Decodable {
    let id: Int
    let results: [String: CountryProviders]
}

struct CountryProviders: Decodable {
    let link: String
    let flatrate: [Provider]?
    let rent: [Provider]?
    let buy: [Provider]?
}

struct Provider: Identifiable, Decodable {
    let providerId: Int
    let providerName: String
    let logoPath: String
    
    var id: Int { providerId }
    
    var logoURL: URL? {
        URL(string: "https://image.tmdb.org/t/p/w500\(logoPath)")
    }
}
