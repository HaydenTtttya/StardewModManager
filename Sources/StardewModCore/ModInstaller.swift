import Foundation

public struct ModInstallResult: Equatable, Sendable {
    public let installedMods: [InstalledMod]
    public let removedMods: [ModItem]

    public init(installedMods: [InstalledMod], removedMods: [ModItem]) {
        self.installedMods = installedMods
        self.removedMods = removedMods
    }

    public var installedCount: Int {
        installedMods.count
    }

    public var replacedCount: Int {
        removedMods.count
    }
}

public struct ModTranslationInstallResult: Equatable, Sendable {
    public let installedFiles: [InstalledTranslationFile]

    public init(installedFiles: [InstalledTranslationFile]) {
        self.installedFiles = installedFiles
    }

    public var installedCount: Int {
        installedFiles.count
    }

    public var createdCount: Int {
        installedFiles.filter { $0.action == .created }.count
    }

    public var overwrittenCount: Int {
        installedFiles.filter { $0.action == .overwritten }.count
    }
}

public struct InstalledTranslationFile: Equatable, Sendable {
    public let sourceURL: URL
    public let destinationURL: URL
    public let action: TranslationFileAction

    public init(sourceURL: URL, destinationURL: URL, action: TranslationFileAction) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.action = action
    }
}

public enum TranslationFileAction: String, Equatable, Sendable {
    case created
    case overwritten
}

public struct InstalledMod: Equatable, Sendable {
    public let manifest: ModManifest
    public let sourceURL: URL
    public let destinationURL: URL

    public init(manifest: ModManifest, sourceURL: URL, destinationURL: URL) {
        self.manifest = manifest
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
    }
}

public enum ModInstallError: LocalizedError, Equatable, Sendable {
    case sourceNotFound(URL)
    case noManifestFound(URL)
    case noTranslationFilesFound(URL)
    case noTranslationTargetFound(URL)
    case unsupportedArchive(URL)
    case archiveExtractionFailed(URL, Int32)
    case sourceInsideModsFolder(URL)

    public var errorDescription: String? {
        switch self {
        case .sourceNotFound(let url):
            "找不到要安装的模组：\(url.path)"
        case .noManifestFound(let url):
            "没有在所选项目中找到 manifest.json：\(url.lastPathComponent)"
        case .noTranslationFilesFound(let url):
            "没有在所选项目中找到可安装的翻译文件：\(url.lastPathComponent)"
        case .noTranslationTargetFound:
            "没有找到可以安装翻译的目标文件。请先选中目标模组，或确认翻译包目录结构和已安装模组一致。"
        case .unsupportedArchive(let url):
            "暂不支持该压缩包格式：\(url.lastPathComponent)"
        case .archiveExtractionFailed(let url, let status):
            "解压失败：\(url.lastPathComponent)（退出码 \(status)）"
        case .sourceInsideModsFolder(let url):
            "不能从当前 Mods 文件夹内部安装：\(url.lastPathComponent)"
        }
    }
}

public enum ModInstaller {
    public static func install(
        sourceURL: URL,
        into rootURL: URL,
        fileManager: FileManager = .default
    ) throws -> ModInstallResult {
        let rootURL = rootURL.standardizedFileURL
        let sourceURL = sourceURL.standardizedFileURL

        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw ModInstallError.sourceNotFound(sourceURL)
        }

        let sourceIsZip = sourceURL.pathExtension.localizedCaseInsensitiveCompare("zip") == .orderedSame
        if !sourceIsZip && (sourceURL.isSameLocation(as: rootURL) || sourceURL.isContained(in: rootURL)) {
            throw ModInstallError.sourceInsideModsFolder(sourceURL)
        }

        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let workingSourceURL: URL
        let cleanupURL: URL?
        if sourceIsZip {
            let cleanupRootURL = fileManager.temporaryDirectory
                .appendingPathComponent("StardewModInstall-\(UUID().uuidString)", isDirectory: true)
            let extractionURL = cleanupRootURL.appendingPathComponent("Expanded", isDirectory: true)
            try fileManager.createDirectory(at: extractionURL, withIntermediateDirectories: true)
            try extractZip(sourceURL, to: extractionURL)
            workingSourceURL = extractionURL
            cleanupURL = cleanupRootURL
        } else if sourceURL.hasDirectoryPath || isDirectory(sourceURL, fileManager: fileManager) {
            workingSourceURL = sourceURL
            cleanupURL = nil
        } else {
            throw ModInstallError.unsupportedArchive(sourceURL)
        }

        defer {
            if let cleanupURL {
                try? fileManager.removeItem(at: cleanupURL)
            }
        }

        let packages = try findInstallablePackages(in: workingSourceURL, fileManager: fileManager)
        guard !packages.isEmpty else {
            throw ModInstallError.noManifestFound(sourceURL)
        }

        let incomingIDs = Set(packages.map { $0.manifest.uniqueID.lowercased() })
        let currentMods = ModScanner.scan(rootURL: rootURL, fileManager: fileManager).mods
        let modsToRemove = currentMods.filter { incomingIDs.contains($0.manifest.uniqueID.lowercased()) }

        for mod in modsToRemove where fileManager.fileExists(atPath: mod.folderURL.path) {
            try fileManager.removeItem(at: mod.folderURL)
        }

        var installedMods: [InstalledMod] = []
        var usedDestinationNames = Set<String>()
        for package in packages {
            let destinationBaseName = destinationFolderName(
                for: package,
                workingSourceURL: workingSourceURL,
                sourceIsZip: sourceIsZip
            )
            let destinationURL = try uniqueDestinationURL(
                named: destinationBaseName,
                in: rootURL,
                usedDestinationNames: &usedDestinationNames,
                fileManager: fileManager
            )
            try fileManager.copyItem(at: package.folderURL, to: destinationURL)
            installedMods.append(
                InstalledMod(
                    manifest: package.manifest,
                    sourceURL: package.folderURL,
                    destinationURL: destinationURL
                )
            )
        }

        return ModInstallResult(installedMods: installedMods, removedMods: modsToRemove)
    }

    public static func installTranslation(
        sourceURL: URL,
        into rootURL: URL,
        targetModURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> ModTranslationInstallResult {
        let rootURL = rootURL.standardizedFileURL
        let sourceURL = sourceURL.standardizedFileURL

        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw ModInstallError.sourceNotFound(sourceURL)
        }

        let sourceIsZip = sourceURL.pathExtension.localizedCaseInsensitiveCompare("zip") == .orderedSame
        if !sourceIsZip && (sourceURL.isSameLocation(as: rootURL) || sourceURL.isContained(in: rootURL)) {
            throw ModInstallError.sourceInsideModsFolder(sourceURL)
        }

        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let workingSourceURL: URL
        let cleanupURL: URL?
        let singleSourceFileURL: URL?
        if sourceIsZip {
            let cleanupRootURL = fileManager.temporaryDirectory
                .appendingPathComponent("StardewTranslationInstall-\(UUID().uuidString)", isDirectory: true)
            let extractionURL = cleanupRootURL.appendingPathComponent("Expanded", isDirectory: true)
            try fileManager.createDirectory(at: extractionURL, withIntermediateDirectories: true)
            try extractZip(sourceURL, to: extractionURL)
            workingSourceURL = extractionURL
            cleanupURL = cleanupRootURL
            singleSourceFileURL = nil
        } else if sourceURL.hasDirectoryPath || isDirectory(sourceURL, fileManager: fileManager) {
            workingSourceURL = sourceURL
            cleanupURL = nil
            singleSourceFileURL = nil
        } else if isRegularFile(sourceURL, fileManager: fileManager) {
            workingSourceURL = sourceURL.deletingLastPathComponent()
            cleanupURL = nil
            singleSourceFileURL = sourceURL
        } else {
            throw ModInstallError.unsupportedArchive(sourceURL)
        }

        defer {
            if let cleanupURL {
                try? fileManager.removeItem(at: cleanupURL)
            }
        }

        let sourceFiles = try findTranslationFiles(
            in: workingSourceURL,
            singleSourceFileURL: singleSourceFileURL,
            fileManager: fileManager
        )
        guard !sourceFiles.isEmpty else {
            throw ModInstallError.noTranslationFilesFound(sourceURL)
        }

        let resolver = try TranslationDestinationResolver(
            rootURL: rootURL,
            sourceRootURL: workingSourceURL,
            targetModURL: targetModURL,
            fileManager: fileManager
        )

        var installedFiles: [InstalledTranslationFile] = []
        var usedDestinationPaths = Set<String>()

        for sourceFileURL in sourceFiles {
            let relativeComponents = relativePathComponents(from: workingSourceURL, to: sourceFileURL)
            let destinations = resolver.destinations(
                for: sourceFileURL,
                relativeComponents: relativeComponents,
                fileManager: fileManager
            )

            for destinationURL in destinations {
                let destinationURL = destinationURL.standardizedFileURL
                guard usedDestinationPaths.insert(destinationURL.path).inserted else {
                    continue
                }

                let action = try copyTranslationFile(
                    from: sourceFileURL,
                    to: destinationURL,
                    fileManager: fileManager
                )
                installedFiles.append(
                    InstalledTranslationFile(
                        sourceURL: sourceFileURL,
                        destinationURL: destinationURL,
                        action: action
                    )
                )
            }
        }

        guard !installedFiles.isEmpty else {
            throw ModInstallError.noTranslationTargetFound(sourceURL)
        }

        return ModTranslationInstallResult(installedFiles: installedFiles)
    }

    private static func findInstallablePackages(
        in sourceURL: URL,
        fileManager: FileManager
    ) throws -> [InstallablePackage] {
        guard let enumerator = fileManager.enumerator(
            at: sourceURL,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var packages: [InstallablePackage] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.lastPathComponent.caseInsensitiveCompare("manifest.json") == .orderedSame else {
                continue
            }

            let folderURL = fileURL.deletingLastPathComponent().standardizedFileURL
            let data = try Data(contentsOf: fileURL)
            let manifest = try ManifestJSONDecoder.decode(ModManifest.self, from: data)
            packages.append(InstallablePackage(manifest: manifest, folderURL: folderURL))
        }

        return packages
            .filter { package in
                !packages.contains { candidate in
                    candidate.folderURL != package.folderURL && package.folderURL.isContained(in: candidate.folderURL)
                }
            }
            .sorted { lhs, rhs in
                lhs.folderURL.path.localizedStandardCompare(rhs.folderURL.path) == .orderedAscending
            }
    }

    private static func findTranslationFiles(
        in sourceURL: URL,
        singleSourceFileURL: URL?,
        fileManager: FileManager
    ) throws -> [URL] {
        if let singleSourceFileURL {
            let relativeComponents = [singleSourceFileURL.lastPathComponent]
            return isInstallableTranslationFile(singleSourceFileURL, relativeComponents: relativeComponents)
                ? [singleSourceFileURL]
                : []
        }

        guard let enumerator = fileManager.enumerator(
            at: sourceURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            guard isRegularFile(fileURL, fileManager: fileManager) else {
                continue
            }

            let relativeComponents = relativePathComponents(from: sourceURL, to: fileURL)
            guard isInstallableTranslationFile(fileURL, relativeComponents: relativeComponents) else {
                continue
            }

            files.append(fileURL.standardizedFileURL)
        }

        return files.sorted {
            $0.path.localizedStandardCompare($1.path) == .orderedAscending
        }
    }

    private static func isInstallableTranslationFile(_ fileURL: URL, relativeComponents: [String]) -> Bool {
        let fileName = fileURL.lastPathComponent
        guard !fileName.hasPrefix("."),
              fileName.caseInsensitiveCompare("manifest.json") != .orderedSame else {
            return false
        }

        if containsI18nPath(relativeComponents) {
            return true
        }

        switch fileURL.pathExtension.lowercased() {
        case "json", "jsonc", "txt", "xnb", "yaml", "yml":
            return true
        default:
            return false
        }
    }

    private static func containsI18nPath(_ components: [String]) -> Bool {
        components.dropLast().contains {
            $0.caseInsensitiveCompare("i18n") == .orderedSame
        }
    }

    private static func relativePathComponents(from rootURL: URL, to fileURL: URL) -> [String] {
        let rootComponents = rootURL.standardizedFileURL.pathComponents
        let fileComponents = fileURL.standardizedFileURL.pathComponents
        guard fileComponents.count > rootComponents.count else {
            return [fileURL.lastPathComponent]
        }

        return Array(fileComponents.dropFirst(rootComponents.count))
    }

    private static func copyTranslationFile(
        from sourceURL: URL,
        to destinationURL: URL,
        fileManager: FileManager
    ) throws -> TranslationFileAction {
        let destinationExisted = fileManager.fileExists(atPath: destinationURL.path)
        try fileManager.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if destinationExisted {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationExisted ? .overwritten : .created
    }

    private static func uniqueDestinationURL(
        named baseName: String,
        in rootURL: URL,
        usedDestinationNames: inout Set<String>,
        fileManager: FileManager
    ) throws -> URL {
        let baseName = sanitizedFolderName(baseName)
        var candidateName = baseName
        var suffix = 2

        while usedDestinationNames.contains(candidateName)
            || fileManager.fileExists(atPath: rootURL.appendingPathComponent(candidateName, isDirectory: true).path) {
            candidateName = "\(baseName) \(suffix)"
            suffix += 1
        }

        usedDestinationNames.insert(candidateName)
        return rootURL.appendingPathComponent(candidateName, isDirectory: true)
    }

    private static func destinationFolderName(
        for package: InstallablePackage,
        workingSourceURL: URL,
        sourceIsZip: Bool
    ) -> String {
        if sourceIsZip && package.folderURL.isSameLocation(as: workingSourceURL) {
            return package.manifest.name
        }

        return package.folderURL.lastPathComponent
    }

    private static func sanitizedFolderName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
        let sanitized = name
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return sanitized.isEmpty ? "Installed Mod" : sanitized
    }

    private static func extractZip(_ archiveURL: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", archiveURL.path, destinationURL.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ModInstallError.archiveExtractionFailed(archiveURL, process.terminationStatus)
        }
    }

    private static func isDirectory(_ url: URL, fileManager: FileManager) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private static func isRegularFile(_ url: URL, fileManager: FileManager) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && !isDirectory.boolValue
    }
}

private struct InstallablePackage: Equatable {
    let manifest: ModManifest
    let folderURL: URL
}

private struct TranslationDestinationResolver {
    let rootURL: URL
    let sourceRootURL: URL
    let targetModURL: URL?
    let installedModFoldersByName: [String: [URL]]
    let groupDirectoriesByName: [String: [URL]]

    init(
        rootURL: URL,
        sourceRootURL: URL,
        targetModURL: URL?,
        fileManager: FileManager
    ) throws {
        self.rootURL = rootURL.standardizedFileURL
        self.sourceRootURL = sourceRootURL.standardizedFileURL

        let installedModFolders = ModScanner.scan(rootURL: rootURL, fileManager: fileManager)
            .mods
            .map { $0.folderURL.standardizedFileURL }

        self.targetModURL = targetModURL
            .map { $0.standardizedFileURL }
            .flatMap { targetURL in
                targetURL.isSameLocation(as: rootURL) || targetURL.isContained(in: rootURL) ? targetURL : nil
            }
        self.installedModFoldersByName = Dictionary(grouping: installedModFolders, by: {
            Self.normalizedName($0.lastPathComponent)
        })
        self.groupDirectoriesByName = try Self.groupDirectoriesByName(
            in: rootURL,
            excluding: installedModFolders,
            fileManager: fileManager
        )
    }

    func destinations(
        for sourceFileURL: URL,
        relativeComponents: [String],
        fileManager: FileManager
    ) -> [URL] {
        let overlayDestinations = self.overlayDestinations(relativeComponents: relativeComponents)
        let canCreateOverlay = Self.containsI18nPath(relativeComponents)
        let usableOverlayDestinations = overlayDestinations.filter { destinationURL in
            canCreateOverlay || fileManager.fileExists(atPath: destinationURL.path)
        }

        if !usableOverlayDestinations.isEmpty {
            return Self.unique(usableOverlayDestinations)
        }

        let fallbackScopes = self.fallbackSearchScopes(relativeComponents: relativeComponents)
        let sameNameDestinations = fallbackScopes.flatMap { scopeURL in
            Self.existingFiles(
                named: sourceFileURL.lastPathComponent,
                in: scopeURL,
                fileManager: fileManager
            )
        }

        if !sameNameDestinations.isEmpty {
            return Self.unique(sameNameDestinations)
        }

        if let targetModURL, Self.shouldCreateI18nFile(relativeComponents: relativeComponents) {
            return [
                targetModURL
                    .appendingPathComponent("i18n", isDirectory: true)
                    .appendingPathComponent(sourceFileURL.lastPathComponent)
            ]
        }

        return []
    }

    private func overlayDestinations(relativeComponents: [String]) -> [URL] {
        guard relativeComponents.count > 1 else {
            return []
        }

        var destinations: [URL] = []
        for componentIndex in relativeComponents.indices.dropLast() {
            let component = relativeComponents[componentIndex]
            let suffix = relativeComponents[(componentIndex + 1)...]
            destinations.append(
                contentsOf: installedModFoldersByName[Self.normalizedName(component), default: []]
                    .map { $0.appendingPathComponents(suffix) }
            )
        }

        let sourceRootName = Self.normalizedName(sourceRootURL.lastPathComponent)
        destinations.append(
            contentsOf: groupDirectoriesByName[sourceRootName, default: []]
                .map { $0.appendingPathComponents(relativeComponents[...]) }
        )

        if let firstComponent = relativeComponents.first {
            let suffix = relativeComponents.dropFirst()
            destinations.append(
                contentsOf: groupDirectoriesByName[Self.normalizedName(firstComponent), default: []]
                    .map { $0.appendingPathComponents(suffix) }
            )
        }

        if let targetModURL, relativeComponents.first?.caseInsensitiveCompare("i18n") == .orderedSame {
            destinations.append(targetModURL.appendingPathComponents(relativeComponents[...]))
        }

        return Self.unique(destinations)
    }

    private func fallbackSearchScopes(relativeComponents: [String]) -> [URL] {
        var scopes: [URL] = []

        if let targetModURL {
            scopes.append(targetModURL)
        }

        for component in relativeComponents.dropLast() {
            scopes.append(
                contentsOf: installedModFoldersByName[Self.normalizedName(component), default: []]
            )
        }

        scopes.append(
            contentsOf: groupDirectoriesByName[Self.normalizedName(sourceRootURL.lastPathComponent), default: []]
        )

        if let firstComponent = relativeComponents.first {
            scopes.append(
                contentsOf: groupDirectoriesByName[Self.normalizedName(firstComponent), default: []]
            )
        }

        return Self.unique(scopes)
    }

    private static func existingFiles(
        named fileName: String,
        in scopeURL: URL,
        fileManager: FileManager
    ) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: scopeURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let fileURL as URL in enumerator where fileURL.lastPathComponent == fileName {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
                  !isDirectory.boolValue else {
                continue
            }
            files.append(fileURL.standardizedFileURL)
        }

        return files.sorted {
            $0.path.localizedStandardCompare($1.path) == .orderedAscending
        }
    }

    private static func groupDirectoriesByName(
        in rootURL: URL,
        excluding installedModFolders: [URL],
        fileManager: FileManager
    ) throws -> [String: [URL]] {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return [:]
        }

        var directories: [URL] = []
        for case let directoryURL as URL in enumerator {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }

            let standardizedURL = directoryURL.standardizedFileURL
            guard !installedModFolders.contains(where: { installedFolderURL in
                standardizedURL.isSameLocation(as: installedFolderURL)
                    || standardizedURL.isContained(in: installedFolderURL)
            }) else {
                continue
            }

            directories.append(standardizedURL)
        }

        return Dictionary(grouping: directories, by: { normalizedName($0.lastPathComponent) })
    }

    private static func shouldCreateI18nFile(relativeComponents: [String]) -> Bool {
        containsI18nPath(relativeComponents)
            || (relativeComponents.count == 1 && relativeComponents[0].lowercased().hasSuffix(".json"))
    }

    private static func containsI18nPath(_ components: [String]) -> Bool {
        components.dropLast().contains {
            $0.caseInsensitiveCompare("i18n") == .orderedSame
        }
    }

    private static func normalizedName(_ name: String) -> String {
        name.lowercased()
    }

    private static func unique(_ urls: [URL]) -> [URL] {
        var seenPaths = Set<String>()
        return urls.filter { url in
            seenPaths.insert(url.standardizedFileURL.path).inserted
        }
    }
}

private extension URL {
    func isSameLocation(as otherURL: URL) -> Bool {
        standardizedFileURL.pathComponents == otherURL.standardizedFileURL.pathComponents
    }

    func isContained(in parentURL: URL) -> Bool {
        let standardizedSelf = standardizedFileURL.pathComponents
        let standardizedParent = parentURL.standardizedFileURL.pathComponents
        guard standardizedSelf.count > standardizedParent.count else {
            return false
        }

        return zip(standardizedSelf, standardizedParent).allSatisfy(==)
    }

    func appendingPathComponents<S: Sequence>(_ components: S) -> URL where S.Element == String {
        components.reduce(self) { url, component in
            url.appendingPathComponent(component)
        }
    }
}
