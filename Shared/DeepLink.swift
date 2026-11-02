import Foundation

/// URLs widgets use to open the app: `steady://home`, `steady://habit/<uuid>`.
enum DeepLink: Hashable, Sendable {
    case home
    case habit(UUID)

    static let scheme = "steady"

    var url: URL {
        switch self {
        case .home: URL(string: "\(Self.scheme)://home")!
        case .habit(let id): URL(string: "\(Self.scheme)://habit/\(id.uuidString)")!
        }
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host() {
        case "home":
            self = .home
        case "habit":
            guard let id = UUID(uuidString: url.lastPathComponent) else { return nil }
            self = .habit(id)
        default:
            return nil
        }
    }
}
