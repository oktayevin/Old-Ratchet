import Foundation

class TMDBClient {
    static let shared = TMDBClient()
    
    private let apiKey = "974f3afd7aea2292c3feb97f0d788e21" // Replace with your actual TMDB API key
    private let baseURL = "https://api.themoviedb.org/3"
    
    enum Endpoint {
        case trendingMovies
        case trendingTVShows
        case movieDetail(id: Int)
        case tvShowDetail(id: Int)
        case tvShowSeason(showId: Int, seasonNumber: Int)
        case searchMulti(query: String)
        case movieWatchProviders(id: Int)
        case tvShowWatchProviders(id: Int)
        
        var path: String {
            switch self {
            case .trendingMovies:
                return "/trending/movie/week"
            case .trendingTVShows:
                return "/trending/tv/week"
            case .movieDetail(let id):
                return "/movie/\(id)"
            case .tvShowDetail(let id):
                return "/tv/\(id)"
            case .tvShowSeason(let showId, let seasonNumber):
                return "/tv/\(showId)/season/\(seasonNumber)"
            case .searchMulti(let query):
                return "/search/multi?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            case .movieWatchProviders(let id):
                return "/movie/\(id)/watch/providers"
            case .tvShowWatchProviders(let id):
                return "/tv/\(id)/watch/providers"
            }
        }
    }
    
    func fetch<T: Decodable>(endpoint: Endpoint) async throws -> T {
        var urlComponents = URLComponents(string: baseURL + endpoint.path)!
        
        // Add API key to all requests
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        if urlComponents.queryItems != nil {
            queryItems.append(contentsOf: urlComponents.queryItems!)
        }
        urlComponents.queryItems = queryItems
        
        let (data, response) = try await URLSession.shared.data(from: urlComponents.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
    
    func fetchWatchProviders(for id: Int, mediaType: MediaType) async throws -> [Provider] {
        let endpoint: Endpoint = mediaType == .movie ? 
            .movieWatchProviders(id: id) : 
            .tvShowWatchProviders(id: id)
        
        let response: WatchProviderResponse = try await fetch(endpoint: endpoint)
        let country = UserSettings.shared.selectedCountry
        
        guard let countryProviders = response.results[country] else {
            return []
        }
        
        var allProviders: [Provider] = []
        
        if let flatrate = countryProviders.flatrate {
            allProviders.append(contentsOf: flatrate)
        }
        if let rent = countryProviders.rent {
            allProviders.append(contentsOf: rent)
        }
        if let buy = countryProviders.buy {
            allProviders.append(contentsOf: buy)
        }
        
        // Convert to array directly without using Set
        return allProviders.reduce(into: [Provider]()) { result, provider in
            if !result.contains(where: { $0.providerId == provider.providerId }) {
                result.append(provider)
            }
        }
    }
} 
