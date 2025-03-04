import Foundation

struct EpisodeProgress {
    let seasonNumber: Int
    let episodeNumber: Int
}

enum WatchStatus: Codable {
    case notInWatchlist
    case watching(progress: Double)
    case watched
    case onHold
    case dropped
    
    private enum CodingKeys: String, CodingKey {
        case type, progress
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "watching":
            let progress = try container.decode(Double.self, forKey: .progress)
            self = .watching(progress: progress)
        case "watched":
            self = .watched
        case "onHold":
            self = .onHold
        case "dropped":
            self = .dropped
        default:
            self = .notInWatchlist
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .watching(let progress):
            try container.encode("watching", forKey: .type)
            try container.encode(progress, forKey: .progress)
        case .watched:
            try container.encode("watched", forKey: .type)
        case .onHold:
            try container.encode("onHold", forKey: .type)
        case .dropped:
            try container.encode("dropped", forKey: .type)
        case .notInWatchlist:
            try container.encode("notInWatchlist", forKey: .type)
        }
    }
}