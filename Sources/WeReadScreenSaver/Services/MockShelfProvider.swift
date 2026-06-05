import Foundation

struct SampleShelfProvider {
    @MainActor
    static func sample() -> any ShelfProviding {
        LocalSampleShelfProvider()
    }
}

private struct LocalSampleShelfProvider: ShelfProviding {
    func loadShelf() async throws -> ShelfPayload {
        ShelfPayload(
            source: "本地样例",
            fetchedAt: .now,
            items: Self.sampleItems
        )
    }

    private static let sampleItems: [ShelfItem] = [
        ShelfItem(
            id: "1",
            title: "Buffett's Early Investments",
            author: "Brett Gardner",
            coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9780231183831-L.jpg"),
            openURL: URL(string: "https://weread.qq.com/web/bookDetail/placeholder-1"),
            kind: .book,
            sortIndex: 1,
            updatedAt: .now
        ),
        ShelfItem(
            id: "2",
            title: "Journey To The Ants",
            author: "Bert Hölldobler",
            coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9780679743255-L.jpg"),
            openURL: URL(string: "https://weread.qq.com/web/bookDetail/placeholder-2"),
            kind: .book,
            sortIndex: 2,
            updatedAt: .now
        ),
        ShelfItem(
            id: "3",
            title: "一只围栏",
            author: "雪球 / 书架样例",
            coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9787220115893-L.jpg"),
            openURL: URL(string: "https://weread.qq.com/web/bookDetail/placeholder-3"),
            kind: .book,
            sortIndex: 3,
            updatedAt: .now
        ),
        ShelfItem(
            id: "4",
            title: "The Education of a Value Investor",
            author: "Guy Spier",
            coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9781250054671-L.jpg"),
            openURL: URL(string: "https://weread.qq.com/web/bookDetail/placeholder-4"),
            kind: .book,
            sortIndex: 4,
            updatedAt: .now
        ),
        ShelfItem(
            id: "5",
            title: "对话亚朵郭仰俊",
            author: "LatePost",
            coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9787559456496-L.jpg"),
            openURL: URL(string: "https://weread.qq.com/web/bookDetail/placeholder-5"),
            kind: .book,
            sortIndex: 5,
            updatedAt: .now
        ),
        ShelfItem(
            id: "6",
            title: "木尽之美",
            author: "华住十五年",
            coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9787569934370-L.jpg"),
            openURL: URL(string: "https://weread.qq.com/web/bookDetail/placeholder-6"),
            kind: .book,
            sortIndex: 6,
            updatedAt: .now
        ),
        ShelfItem(
            id: "7",
            title: "马丁·惠特曼的价值投资方法",
            author: "Martin J. Whitman",
            coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9787111680939-L.jpg"),
            openURL: URL(string: "https://weread.qq.com/web/bookDetail/placeholder-7"),
            kind: .book,
            sortIndex: 7,
            updatedAt: .now
        ),
        ShelfItem(
            id: "8",
            title: "价值投资",
            author: "格雷厄姆",
            coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9787508633299-L.jpg"),
            openURL: URL(string: "https://weread.qq.com/web/bookDetail/placeholder-8"),
            kind: .book,
            sortIndex: 8,
            updatedAt: .now
        )
    ]
}
