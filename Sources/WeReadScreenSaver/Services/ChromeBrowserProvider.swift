import CommonCrypto
import Darwin
import Foundation
import Security
import SQLite3

struct ChromeBrowserShelfProvider: ShelfProviding {
    let fallback: ShelfProviding

    func loadShelf() async throws -> ShelfPayload {
        do {
            if let payload = try await ChromeCookieShelfReader.loadShelfFromChromeCookies() {
                return payload
            }
        } catch {
            // The saver should remain visible even if Chrome cookies are missing,
            // locked, or temporarily unreadable.
        }

        if let payload = ChromeShelfCacheStore().load() {
            return payload
        }

        return try await fallback.loadShelf()
    }
}

final class ChromeShelfCacheStore {
    private let fileManager = FileManager.default

    private var cacheURL: URL {
        let base = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/WeReadScreenSaver", isDirectory: true)
        return base.appendingPathComponent("shelf-cache.json")
    }

    func load() -> ShelfPayload? {
        load(from: cacheURL) ?? loadBundledCache()
    }

    func save(_ payload: ShelfPayload) {
        do {
            try fileManager.createDirectory(
                at: cacheURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder.weRead.encode(payload)
            try data.write(to: cacheURL, options: [.atomic])
        } catch {
            // Ignore cache write failures. The app still works from memory.
        }
    }

    private func load(from url: URL) -> ShelfPayload? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder.weRead.decode(ShelfPayload.self, from: data)
    }

    private func loadBundledCache() -> ShelfPayload? {
        if let payload = loadFromLoadedImagePath() {
            return payload
        }

        let bundles = [Bundle(for: WeReadBundleMarker.self), Bundle.main] + Bundle.allBundles
        for bundle in bundles {
            if let url = bundle.url(forResource: "shelf-cache", withExtension: "json"),
               let payload = load(from: url) {
                return payload
            }
        }
        return nil
    }

    private func loadFromLoadedImagePath() -> ShelfPayload? {
        for index in 0..<_dyld_image_count() {
            guard let name = _dyld_get_image_name(index) else {
                continue
            }

            let imagePath = String(cString: name)
            guard imagePath.contains("WeReadScreenSaver.saver/Contents/MacOS/WeReadScreenSaver") else {
                continue
            }

            let resourceURL = URL(fileURLWithPath: imagePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/shelf-cache.json")
            if let payload = load(from: resourceURL) {
                return payload
            }
        }
        return nil
    }
}

private final class WeReadBundleMarker: NSObject {}

enum ChromeCookieShelfReader {
    static func loadShelfFromChromeCookies() async throws -> ShelfPayload? {
        try await Task.detached(priority: .userInitiated) { () async throws -> ShelfPayload? in
            let profiles = try ChromeProfileStore().profilesWithCookieStores()
            guard !profiles.isEmpty else {
                return nil
            }

            let decryptor = try ChromeCookieDecryptor()
            var lastError: Error?

            for profile in profiles {
                do {
                    let cookies = try profile.loadWeReadCookies(decryptor: decryptor)
                    guard cookies.hasLoginCookie else {
                        continue
                    }

                    let payload = try await WeReadWebShelfClient(cookies: cookies).loadShelf()
                    guard !payload.items.isEmpty else {
                        continue
                    }
                    return payload
                } catch {
                    lastError = error
                }
            }

            if let lastError {
                throw lastError
            }
            return nil
        }.value
    }
}

private struct ChromeProfileStore {
    private let fileManager = FileManager.default

    func profilesWithCookieStores() throws -> [ChromeProfile] {
        let chromeRoot = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Google/Chrome", isDirectory: true)

        let profileDirectories = try fileManager.contentsOfDirectory(
            at: chromeRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        return profileDirectories
            .filter { url in
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
                return values?.isDirectory == true
                    && fileManager.fileExists(atPath: url.appendingPathComponent("Cookies").path)
            }
            .sorted { lhs, rhs in
                profileSortKey(lhs.lastPathComponent) < profileSortKey(rhs.lastPathComponent)
            }
            .map { ChromeProfile(name: $0.lastPathComponent, cookiesURL: $0.appendingPathComponent("Cookies")) }
    }

    private func profileSortKey(_ name: String) -> String {
        if name == "Default" {
            return "000-\(name)"
        }
        return "100-\(name)"
    }
}

private struct ChromeProfile {
    let name: String
    let cookiesURL: URL

    func loadWeReadCookies(decryptor: ChromeCookieDecryptor) throws -> WeReadCookieJar {
        var database: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(cookiesURL.path, &database, flags, nil) == SQLITE_OK, let database else {
            throw ChromeCookieError.sqliteOpenFailed
        }
        defer {
            sqlite3_close(database)
        }

        let sql = """
        SELECT host_key, name, value, encrypted_value
        FROM cookies
        WHERE host_key LIKE ?
        ORDER BY host_key, name
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw ChromeCookieError.sqliteQueryFailed
        }
        defer {
            sqlite3_finalize(statement)
        }

        sqlite3_bind_text(statement, 1, "%weread.qq.com%", -1, SQLITE_TRANSIENT)

        var values: [String: String] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            let host = String(cString: sqlite3_column_text(statement, 0))
            let name = String(cString: sqlite3_column_text(statement, 1))
            let value = String(cString: sqlite3_column_text(statement, 2))

            if !value.isEmpty {
                values[name] = value
                continue
            }

            let encryptedLength = Int(sqlite3_column_bytes(statement, 3))
            guard encryptedLength > 0, let encryptedBytes = sqlite3_column_blob(statement, 3) else {
                continue
            }

            let encryptedValue = Data(bytes: encryptedBytes, count: encryptedLength)
            if let decrypted = try? decryptor.decrypt(encryptedValue, hostKey: host) {
                values[name] = decrypted
            }
        }

        return WeReadCookieJar(profileName: name, values: values)
    }
}

private struct WeReadCookieJar {
    let profileName: String
    let values: [String: String]

    var hasLoginCookie: Bool {
        values["wr_vid"]?.isEmpty == false
            && values["wr_skey"]?.isEmpty == false
    }

    var headerValue: String {
        values
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "; ")
    }
}

private final class ChromeCookieDecryptor {
    private let key: Data
    private let initializationVector = Data(repeating: 0x20, count: kCCBlockSizeAES128)

    init() throws {
        let password = try Self.loadChromeSafeStoragePassword()
        self.key = try Self.deriveKey(from: password)
    }

    func decrypt(_ encryptedValue: Data, hostKey: String) throws -> String {
        let ciphertext = encryptedValue.starts(with: Data("v10".utf8))
            ? encryptedValue.dropFirst(3)
            : encryptedValue[...]
        let decrypted = try decryptCBC(Data(ciphertext))
        let hostDigest = sha256(Data(hostKey.utf8))
        let valueData = decrypted.starts(with: hostDigest)
            ? decrypted.dropFirst(hostDigest.count)
            : decrypted[...]

        guard let value = String(data: Data(valueData), encoding: .utf8) else {
            throw ChromeCookieError.cookieDecodeFailed
        }
        return value
    }

    private func decryptCBC(_ ciphertext: Data) throws -> Data {
        var output = Data(count: ciphertext.count + kCCBlockSizeAES128)
        let outputCapacity = output.count
        var outputLength = 0

        let status = output.withUnsafeMutableBytes { outputBytes in
            ciphertext.withUnsafeBytes { cipherBytes in
                key.withUnsafeBytes { keyBytes in
                    initializationVector.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress,
                            kCCKeySizeAES128,
                            ivBytes.baseAddress,
                            cipherBytes.baseAddress,
                            ciphertext.count,
                            outputBytes.baseAddress,
                            outputCapacity,
                            &outputLength
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else {
            throw ChromeCookieError.cookieDecryptFailed
        }

        output.removeSubrange(outputLength..<output.count)
        return output
    }

    private static func loadChromeSafeStoragePassword() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Chrome Safe Storage",
            kSecAttrAccount as String: "Chrome",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, !data.isEmpty else {
            throw ChromeCookieError.safeStoragePasswordUnavailable
        }
        return data
    }

    private static func deriveKey(from password: Data) throws -> Data {
        var key = Data(count: kCCKeySizeAES128)
        let keyLength = key.count
        let salt = Data("saltysalt".utf8)

        let status = password.withUnsafeBytes { passwordBytes in
            salt.withUnsafeBytes { saltBytes in
                key.withUnsafeMutableBytes { keyBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress,
                        password.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
                        1003,
                        keyBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw ChromeCookieError.keyDerivationFailed
        }
        return key
    }

    private func sha256(_ data: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest)
    }
}

private struct WeReadWebShelfClient {
    let cookies: WeReadCookieJar

    func loadShelf() async throws -> ShelfPayload {
        guard let url = URL(string: "https://weread.qq.com/web/shelf/sync") else {
            throw WeReadWebError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue(cookies.headerValue, forHTTPHeaderField: "Cookie")
        request.setValue("https://weread.qq.com/web/shelf", forHTTPHeaderField: "Referer")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/137 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw WeReadWebError.requestFailed
        }

        let shelfResponse = try JSONDecoder.weRead.decode(WeReadShelfSyncResponse.self, from: data)
        return shelfResponse.shelfPayload(profileName: cookies.profileName)
    }
}

private struct WeReadShelfSyncResponse: Decodable {
    let books: [WeReadBook]?
    let lectureBooks: [WeReadBook]?

    func shelfPayload(profileName: String) -> ShelfPayload {
        var index = 0
        var items: [ShelfItem] = []

        for book in books ?? [] {
            guard let item = book.shelfItem(kind: .book, sortIndex: index) else {
                continue
            }
            items.append(item)
            index += 1
        }

        for album in lectureBooks ?? [] {
            guard let item = album.shelfItem(kind: .album, sortIndex: index) else {
                continue
            }
            items.append(item)
            index += 1
        }

        return ShelfPayload(
            source: "Chrome 登录态",
            fetchedAt: .now,
            items: items
        )
    }
}

private struct WeReadBook: Decodable {
    let bookId: String
    let title: String?
    let author: String?
    let cover: String?
    let type: Int?
    let updateTime: TimeInterval?
    let readUpdateTime: TimeInterval?

    func shelfItem(kind: ShelfItem.Kind, sortIndex: Int) -> ShelfItem? {
        guard !isPrivateUpload,
              let title,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let coverURL = cover.flatMap(URL.init(string:))
        return ShelfItem(
            id: bookId,
            title: title,
            author: author ?? "",
            coverURL: coverURL,
            openURL: URL(string: "https://weread.qq.com/web/bookDetail/\(bookId)"),
            kind: kind,
            sortIndex: sortIndex,
            updatedAt: Date(timeIntervalSince1970: readUpdateTime ?? updateTime ?? 0)
        )
    }

    private var isPrivateUpload: Bool {
        type == 11 || bookId.hasPrefix("CB_")
    }
}

enum ChromeCookieError: LocalizedError {
    case safeStoragePasswordUnavailable
    case keyDerivationFailed
    case sqliteOpenFailed
    case sqliteQueryFailed
    case cookieDecryptFailed
    case cookieDecodeFailed

    var errorDescription: String? {
        switch self {
        case .safeStoragePasswordUnavailable:
            return "无法读取 Chrome Safe Storage。"
        case .keyDerivationFailed:
            return "无法解密 Chrome 登录态。"
        case .sqliteOpenFailed:
            return "无法打开 Chrome Cookie 数据库。"
        case .sqliteQueryFailed:
            return "无法查询 Chrome Cookie 数据库。"
        case .cookieDecryptFailed:
            return "无法解密 Chrome Cookie。"
        case .cookieDecodeFailed:
            return "无法解析 Chrome Cookie。"
        }
    }
}

enum WeReadWebError: LocalizedError {
    case invalidURL
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "微信读书接口地址无效。"
        case .requestFailed:
            return "微信读书书架同步失败。"
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension JSONDecoder {
    static var weRead: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var weRead: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
