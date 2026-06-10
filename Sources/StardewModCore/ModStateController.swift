import Foundation

public struct ModStateChangeResult: Equatable, Sendable {
    public let sourceURL: URL
    public let destinationURL: URL
    public let isEnabled: Bool

    public init(sourceURL: URL, destinationURL: URL, isEnabled: Bool) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.isEnabled = isEnabled
    }
}

public enum ModStateChangeError: LocalizedError, Equatable, Sendable {
    case sourceNotFound(URL)
    case disabledByParentDirectory(URL)

    public var errorDescription: String? {
        switch self {
        case .sourceNotFound(let url):
            "找不到模组文件夹：\(url.path)"
        case .disabledByParentDirectory(let url):
            "此模组是被上级目录禁用的，无法只启用单个模组：\(url.path)"
        }
    }
}

public enum ModStateController {
    private static let disabledSuffix = ".disabled"

    public static func setEnabled(
        _ isEnabled: Bool,
        for mod: ModItem,
        fileManager: FileManager = .default
    ) throws -> ModStateChangeResult {
        let sourceURL = mod.folderURL.standardizedFileURL
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw ModStateChangeError.sourceNotFound(sourceURL)
        }

        let currentlyEnabled = !mod.isDisabled
        guard currentlyEnabled != isEnabled else {
            return ModStateChangeResult(
                sourceURL: sourceURL,
                destinationURL: sourceURL,
                isEnabled: isEnabled
            )
        }

        let destinationURL = try destinationURL(
            for: sourceURL,
            isEnabled: isEnabled,
            fileManager: fileManager
        )
        try fileManager.moveItem(at: sourceURL, to: destinationURL)

        return ModStateChangeResult(
            sourceURL: sourceURL,
            destinationURL: destinationURL.standardizedFileURL,
            isEnabled: isEnabled
        )
    }

    private static func destinationURL(
        for sourceURL: URL,
        isEnabled: Bool,
        fileManager: FileManager
    ) throws -> URL {
        let parentURL = sourceURL.deletingLastPathComponent()
        let sourceName = sourceURL.lastPathComponent

        if isEnabled {
            let enabledName = enabledFolderName(from: sourceName)
            guard enabledName != sourceName else {
                throw ModStateChangeError.disabledByParentDirectory(sourceURL)
            }

            return uniqueDestinationURL(
                named: enabledName,
                in: parentURL,
                fileManager: fileManager
            )
        }

        return uniqueDestinationURL(
            named: disabledFolderName(from: sourceName),
            in: parentURL,
            fileManager: fileManager
        )
    }

    private static func enabledFolderName(from sourceName: String) -> String {
        var name = sourceName

        if name.hasSuffix(disabledSuffix) {
            name = String(name.dropLast(disabledSuffix.count))
        }

        if name.hasPrefix(".") {
            name = String(name.dropFirst())
        }

        return sanitizedFolderName(name, fallback: "Enabled Mod")
    }

    private static func disabledFolderName(from sourceName: String) -> String {
        var name = sourceName

        if name.hasPrefix(".") {
            name = String(name.dropFirst())
        }

        if !name.hasSuffix(disabledSuffix) {
            name += disabledSuffix
        }

        return sanitizedFolderName(name, fallback: "Disabled Mod\(disabledSuffix)")
    }

    private static func uniqueDestinationURL(
        named baseName: String,
        in parentURL: URL,
        fileManager: FileManager
    ) -> URL {
        let baseName = sanitizedFolderName(baseName, fallback: "Mod")
        let nameExtension = (baseName as NSString).pathExtension
        let stem = nameExtension.isEmpty
            ? baseName
            : (baseName as NSString).deletingPathExtension

        var candidateName = baseName
        var suffix = 2

        while fileManager.fileExists(atPath: parentURL.appendingPathComponent(candidateName, isDirectory: true).path) {
            candidateName = nameExtension.isEmpty
                ? "\(stem) \(suffix)"
                : "\(stem) \(suffix).\(nameExtension)"
            suffix += 1
        }

        return parentURL.appendingPathComponent(candidateName, isDirectory: true)
    }

    private static func sanitizedFolderName(_ name: String, fallback: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
        let sanitized = name
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return sanitized.isEmpty ? fallback : sanitized
    }
}
