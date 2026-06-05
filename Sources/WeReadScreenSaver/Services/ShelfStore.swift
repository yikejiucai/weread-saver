import Foundation
import Combine

@MainActor
final class ShelfStore: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded
        case empty
        case failed(String)
    }

    private let provider: any ShelfProviding
    private let cache = ChromeShelfCacheStore()

    @Published var state: State = .loading
    @Published var items: [ShelfItem] = []
    @Published var sourceLabel: String = "正在同步"

    init(provider: any ShelfProviding) {
        self.provider = provider
        if let cached = cache.load() {
            items = cached.items
            sourceLabel = cached.source
            state = cached.items.isEmpty ? .empty : .loaded
        }
    }

    func refresh() async {
        do {
            state = .loading
            let payload = try await provider.loadShelf()
            apply(payload)
        } catch {
            if items.isEmpty {
                state = .failed(error.localizedDescription)
            } else {
                sourceLabel = "离线缓存"
            }
        }
    }

    func apply(_ payload: ShelfPayload, sourceOverride: String? = nil) {
        items = payload.items.sorted { lhs, rhs in
            if lhs.sortIndex != rhs.sortIndex {
                return lhs.sortIndex < rhs.sortIndex
            }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
        sourceLabel = sourceOverride ?? payload.source
        state = items.isEmpty ? .empty : .loaded
        cache.save(payload)
    }
}

@MainActor
protocol ShelfProviding {
    func loadShelf() async throws -> ShelfPayload
}
