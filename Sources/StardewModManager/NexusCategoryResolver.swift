import Foundation

actor NexusCategoryResolver {
    private let session: URLSession
    private var cache: [Int: String] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func categories(for modIDs: Set<Int>) async -> [Int: String] {
        var resolved: [Int: String] = [:]
        let missingIDs = modIDs.filter { modID in
            if let category = cache[modID] {
                resolved[modID] = category
                return false
            }
            return true
        }

        await withTaskGroup(of: (Int, String?).self) { group in
            for modID in missingIDs {
                group.addTask { [session] in
                    let category = await Self.fetchCategory(for: modID, session: session)
                    return (modID, category)
                }
            }

            for await (modID, category) in group {
                guard let category else {
                    continue
                }
                cache[modID] = category
                resolved[modID] = category
            }
        }

        return resolved
    }

    private static func fetchCategory(for modID: Int, session: URLSession) async -> String? {
        guard let url = URL(string: "https://www.nexusmods.com/stardewvalley/mods/\(modID)") else {
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let html = String(data: data, encoding: .utf8) else {
                return nil
            }
            return parseCategory(from: html)
        } catch {
            return nil
        }
    }

    private static func parseCategory(from html: String) -> String? {
        let pattern = #"<a[^>]+href=[\"'](?:https://www\.nexusmods\.com)?/stardewvalley/mods/categories/\d+[\"'][^>]*>(.*?)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let categoryRange = Range(match.range(at: 1), in: html) else {
            return nil
        }

        return html[categoryRange]
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
