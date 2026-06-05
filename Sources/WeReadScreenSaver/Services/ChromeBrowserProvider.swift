import Foundation

struct ChromeBrowserShelfProvider: ShelfProviding {
    let fallback: ShelfProviding

    func loadShelf() async throws -> ShelfPayload {
        if let payload = try await ChromeBrowserDirectReader.loadShelfFromChrome() {
            return payload
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
        guard let data = try? Data(contentsOf: cacheURL) else {
            return nil
        }
        return try? JSONDecoder.weRead.decode(ShelfPayload.self, from: data)
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
}

enum ChromeBrowserDirectReader {
    static func loadShelfFromChrome() async throws -> ShelfPayload? {
        let json = try await Task.detached(priority: .userInitiated) {
            try capturePayloadJSONString()
        }.value

        guard let json else {
            return nil
        }

        guard let data = json.data(using: .utf8) else {
            throw ChromeBrowserError.invalidOutput
        }

        return try JSONDecoder.weRead.decode(ShelfPayload.self, from: data)
    }

    private static func capturePayloadJSONString() throws -> String? {
        let scriptURL = try writeJavaScriptBundle()
        defer {
            try? FileManager.default.removeItem(at: scriptURL)
        }

        let appleScript = """
        set jsPath to POSIX file "\(scriptURL.path)"
        set jsSource to read jsPath as «class utf8»
        tell application "Google Chrome"
            if not (exists front window) then error "Chrome 没有前台窗口"
            set targetTab to active tab of front window
            set tabURL to URL of targetTab
            if tabURL does not contain "weread.qq.com" then error "请先切到微信读书网页标签页"
            set resultText to execute javascript jsSource in targetTab
        end tell
        return resultText
        """

        let output = try runAppleScript(appleScript)
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func writeJavaScriptBundle() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("weread-browser-\(UUID().uuidString).js")
        try javaScriptBundle.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func runAppleScript(_ script: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-l", "AppleScript", "-e", script]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let errorMessage = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                ?? "Chrome automation failed"
            throw ChromeBrowserError.appleScriptFailed(errorMessage)
        }

        guard let output = String(data: outputData, encoding: .utf8) else {
            throw ChromeBrowserError.invalidOutput
        }

        return output
    }

    private static let javaScriptBundle = """
    (() => {
      function normalizeText(text) {
        return String(text || "").replace(/\\s+/g, " ").trim();
      }

      function absoluteUrl(value) {
        if (!value) return null;
        try {
          return new URL(value, location.href).toString();
        } catch {
          return null;
        }
      }

      function extractTitle(card, image) {
        const candidates = [
          image?.alt,
          image?.getAttribute("title"),
          card?.getAttribute("aria-label"),
          card?.dataset?.title
        ];

        for (const candidate of candidates) {
          const normalized = normalizeText(candidate);
          if (normalized) return normalized;
        }

        const lines = normalizeText(card?.innerText).split(" ");
        return lines.find(Boolean) || "未命名书籍";
      }

      function extractAuthor(card, title) {
        const text = normalizeText(card?.innerText);
        if (!text) return "";

        const segments = text
          .split(/\\n|·|\\|/)
          .map(normalizeText)
          .filter(Boolean);

        const titleIndex = segments.findIndex((line) => line.includes(title));
        if (titleIndex >= 0 && segments[titleIndex + 1]) {
          return segments[titleIndex + 1];
        }

        return segments[1] || "";
      }

      function inferKind(card, href) {
        const text = normalizeText(`${card?.innerText || ""} ${card?.getAttribute("aria-label") || ""} ${href || ""}`);
        return /(专辑|听书|音频|audio|album)/i.test(text) ? "album" : "book";
      }

      function getBookId(href) {
        try {
          const url = new URL(href, location.href);
          const parts = url.pathname.split("/").filter(Boolean);
          return parts[parts.length - 1] || href;
        } catch {
          return href;
        }
      }

      const anchors = Array.from(document.querySelectorAll('a[href*="/web/bookDetail/"]'));
      const seen = new Set();
      const items = [];

      for (const anchor of anchors) {
        const href = absoluteUrl(anchor.getAttribute("href"));
        if (!href) continue;

        const id = getBookId(href);
        if (seen.has(id)) continue;
        seen.add(id);

        const card = anchor.closest("li, article, section, div") || anchor;
        const image = card.querySelector("img") || anchor.querySelector("img");
        const title = extractTitle(card, image);
        const author = extractAuthor(card, title);
        const coverURL = absoluteUrl(
          image?.currentSrc || image?.src || image?.getAttribute("data-src") || image?.getAttribute("data-original")
        );

        items.push({
          id,
          title,
          author,
          coverURL,
          openURL: href,
          kind: inferKind(card, href),
          sortIndex: items.length,
          updatedAt: new Date().toISOString()
        });
      }

      return JSON.stringify({
        source: "Chrome Login",
        fetchedAt: new Date().toISOString(),
        items
      });
    })()
    """
}

enum ChromeBrowserError: LocalizedError {
    case invalidOutput
    case appleScriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidOutput:
            return "无法解析 Chrome 返回的数据。"
        case .appleScriptFailed(let message):
            return message
        }
    }
}

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
