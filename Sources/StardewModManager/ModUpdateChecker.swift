import Foundation
import StardewModCore

enum ModUpdateStatus: Equatable, Sendable {
    case notChecked
    case checking
    case current
    case updateAvailable(version: String, url: URL?)
    case failed(String)

    var isUpdateAvailable: Bool {
        if case .updateAvailable = self {
            return true
        }
        return false
    }
}

actor ModUpdateChecker {
    private let session: URLSession
    private var cache: [String: ModUpdateStatus] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func updateStatuses(for mods: [ModItem]) async -> [ModItem.ID: ModUpdateStatus] {
        var statuses: [ModItem.ID: ModUpdateStatus] = [:]
        var uncachedMods: [ModItem] = []

        for mod in mods {
            let key = cacheKey(for: mod)
            if let status = cache[key] {
                statuses[mod.id] = status
            } else {
                uncachedMods.append(mod)
            }
        }

        guard !uncachedMods.isEmpty else {
            return statuses
        }

        do {
            let resolvedStatuses = try await fetchUpdateStatuses(for: uncachedMods)
            for mod in uncachedMods {
                let status = resolvedStatuses[mod.manifest.uniqueID] ?? .current
                cache[cacheKey(for: mod)] = status
                statuses[mod.id] = status
            }
        } catch {
            for mod in uncachedMods {
                let message = (error as? ModUpdateCheckerError)?.messageKey ?? error.localizedDescription
                statuses[mod.id] = .failed(message)
            }
        }

        return statuses
    }

    private func fetchUpdateStatuses(for mods: [ModItem]) async throws -> [String: ModUpdateStatus] {
        let request = ModUpdateRequest(
            mods: mods.map { mod in
                ModUpdateRequestEntry(
                    id: mod.manifest.uniqueID,
                    installedVersion: mod.manifest.version,
                    updateKeys: mod.manifest.updateKeys,
                    isBroken: mod.hasIssues
                )
            }
        )

        var urlRequest = URLRequest(url: URL(string: "https://smapi.io/api/v4.0.0/mods")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw ModUpdateCheckerError.requestFailed
        }

        let responses = try JSONDecoder().decode([ModUpdateResponse].self, from: data)
        var statuses: [String: ModUpdateStatus] = [:]
        for response in responses {
            if let update = response.suggestedUpdate {
                statuses[response.id] = .updateAvailable(version: update.version, url: update.url)
            } else if let firstError = response.errors?.first {
                statuses[response.id] = .failed(firstError)
            } else {
                statuses[response.id] = .current
            }
        }

        return statuses
    }

    private func cacheKey(for mod: ModItem) -> String {
        [
            mod.manifest.uniqueID,
            mod.manifest.version,
            mod.manifest.updateKeys?.joined(separator: ",") ?? ""
        ].joined(separator: "|")
    }
}

private struct ModUpdateRequest: Encodable {
    let apiVersion = "4.0.0"
    let gameVersion = "1.6.14"
    let platform = "Mac"
    let mods: [ModUpdateRequestEntry]

    enum CodingKeys: String, CodingKey {
        case apiVersion = "ApiVersion"
        case gameVersion = "GameVersion"
        case platform = "Platform"
        case mods = "Mods"
    }
}

private struct ModUpdateRequestEntry: Encodable {
    let id: String
    let installedVersion: String
    let updateKeys: [String]?
    let isBroken: Bool

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case installedVersion = "InstalledVersion"
        case updateKeys = "UpdateKeys"
        case isBroken = "IsBroken"
    }
}

private struct ModUpdateResponse: Decodable {
    let id: String
    let suggestedUpdate: SuggestedModUpdate?
    let errors: [String]?
}

private struct SuggestedModUpdate: Decodable {
    let version: String
    let url: URL?
}

private enum ModUpdateCheckerError: Error {
    case requestFailed

    var messageKey: String {
        switch self {
        case .requestFailed:
            "modUpdate.requestFailed"
        }
    }
}
