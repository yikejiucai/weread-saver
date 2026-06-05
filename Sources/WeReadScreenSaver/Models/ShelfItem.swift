import Foundation

struct ShelfItem: Identifiable, Codable, Hashable, Sendable {
    enum Kind: String, Codable {
        case book
        case album
    }

    let id: String
    let title: String
    let author: String
    let coverURL: URL?
    let openURL: URL?
    let kind: Kind
    let sortIndex: Int
    let updatedAt: Date?
}

struct ShelfPayload: Codable, Sendable {
    let source: String
    let fetchedAt: Date
    let items: [ShelfItem]
}
