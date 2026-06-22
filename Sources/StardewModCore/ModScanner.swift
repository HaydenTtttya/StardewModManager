import Foundation

public struct ModScanResult: Equatable, Sendable {
    public let rootURL: URL
    public let mods: [ModItem]
    public let errors: [ModScanError]

    public init(rootURL: URL, mods: [ModItem], errors: [ModScanError]) {
        self.rootURL = rootURL
        self.mods = mods
        self.errors = errors
    }
}

public struct ModItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let manifest: ModManifest
    public let folderURL: URL
    public let relativePath: String
    public let isDisabled: Bool
    public let missingRequiredDependencies: [String]
    public let missingOptionalDependencies: [String]
    public let isDuplicateUniqueID: Bool

    public init(
        manifest: ModManifest,
        folderURL: URL,
        relativePath: String,
        isDisabled: Bool,
        missingRequiredDependencies: [String] = [],
        missingOptionalDependencies: [String] = [],
        isDuplicateUniqueID: Bool = false
    ) {
        self.id = folderURL.path
        self.manifest = manifest
        self.folderURL = folderURL
        self.relativePath = relativePath
        self.isDisabled = isDisabled
        self.missingRequiredDependencies = missingRequiredDependencies
        self.missingOptionalDependencies = missingOptionalDependencies
        self.isDuplicateUniqueID = isDuplicateUniqueID
    }

    public var hasIssues: Bool {
        isDuplicateUniqueID || !missingRequiredDependencies.isEmpty
    }

    public var status: ModStatus {
        if isDisabled {
            return .disabled
        }
        if hasIssues {
            return .needsAttention
        }
        return .enabled
    }
}

public enum ModStatus: String, Codable, Sendable {
    case enabled
    case disabled
    case needsAttention

    public var label: String {
        switch self {
        case .enabled:
            "已启用"
        case .disabled:
            "已禁用"
        case .needsAttention:
            "需处理"
        }
    }
}

public struct ModScanError: Identifiable, Equatable, Sendable {
    public let id: String
    public let fileURL: URL
    public let message: String

    public init(fileURL: URL, message: String) {
        self.id = fileURL.path
        self.fileURL = fileURL
        self.message = message
    }
}

public enum ModScanner {
    public static func scan(rootURL: URL, fileManager: FileManager = .default) -> ModScanResult {
        let rootURL = rootURL.standardizedFileURL
        var mods: [ModItem] = []
        var errors: [ModScanError] = []

        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [],
            errorHandler: { url, error in
                errors.append(ModScanError(fileURL: url, message: error.localizedDescription))
                return true
            }
        ) else {
            return ModScanResult(
                rootURL: rootURL,
                mods: [],
                errors: [ModScanError(fileURL: rootURL, message: "无法读取目录")]
            )
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.lastPathComponent.caseInsensitiveCompare("manifest.json") == .orderedSame else {
                continue
            }

            do {
                let data = try Data(contentsOf: fileURL)
                let manifest = try ManifestJSONDecoder.decode(ModManifest.self, from: data)
                let folderURL = fileURL.deletingLastPathComponent().standardizedFileURL
                let relativePath = relativePath(from: rootURL, to: folderURL)

                mods.append(
                    ModItem(
                        manifest: manifest,
                        folderURL: folderURL,
                        relativePath: relativePath,
                        isDisabled: containsDisabledPathComponent(relativePath)
                    )
                )
            } catch {
                errors.append(ModScanError(fileURL: fileURL, message: describeDecodingError(error)))
            }
        }

        let enrichedMods = enrichDependencyState(for: mods)
            .sorted { lhs, rhs in
                lhs.manifest.name.localizedStandardCompare(rhs.manifest.name) == .orderedAscending
            }

        return ModScanResult(rootURL: rootURL, mods: enrichedMods, errors: errors)
    }

    private static func enrichDependencyState(for mods: [ModItem]) -> [ModItem] {
        let availableIDs = Set(mods.map { $0.manifest.uniqueID.lowercased() })
        let duplicateIDs = Set(
            Dictionary(grouping: mods, by: { $0.manifest.uniqueID.lowercased() })
                .filter { $0.value.count > 1 }
                .map(\.key)
        )

        return mods.map { mod in
            let dependencies = mod.manifest.dependencies ?? []
            let missingRequired = dependencies
                .filter { $0.required && !availableIDs.contains($0.uniqueID.lowercased()) }
                .map(\.uniqueID)
                .sorted()
            let missingOptional = dependencies
                .filter { !$0.required && !availableIDs.contains($0.uniqueID.lowercased()) }
                .map(\.uniqueID)
                .sorted()

            return ModItem(
                manifest: mod.manifest,
                folderURL: mod.folderURL,
                relativePath: mod.relativePath,
                isDisabled: mod.isDisabled,
                missingRequiredDependencies: missingRequired,
                missingOptionalDependencies: missingOptional,
                isDuplicateUniqueID: duplicateIDs.contains(mod.manifest.uniqueID.lowercased())
            )
        }
    }

    private static func relativePath(from rootURL: URL, to folderURL: URL) -> String {
        let rootComponents = rootURL.pathComponents
        let folderComponents = folderURL.pathComponents
        let suffix = folderComponents.dropFirst(rootComponents.count)
        return suffix.joined(separator: "/")
    }

    private static func containsDisabledPathComponent(_ relativePath: String) -> Bool {
        relativePath
            .split(separator: "/")
            .contains { component in
                component.hasPrefix(".") || component.hasSuffix(".disabled")
            }
    }

    private static func describeDecodingError(_ error: Error) -> String {
        switch error {
        case DecodingError.dataCorrupted(let context):
            "Data corrupted at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        case DecodingError.keyNotFound(let key, let context):
            "Missing key \(key.stringValue) at \(codingPathDescription(context.codingPath))"
        case DecodingError.typeMismatch(let type, let context):
            "Type mismatch for \(type) at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        case DecodingError.valueNotFound(let type, let context):
            "Missing value for \(type) at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        default:
            error.localizedDescription
        }
    }

    private static func codingPathDescription(_ codingPath: [CodingKey]) -> String {
        guard !codingPath.isEmpty else {
            return "<root>"
        }

        return codingPath.map(\.stringValue).joined(separator: ".")
    }
}
