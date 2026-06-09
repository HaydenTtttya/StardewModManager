import AppKit
import Foundation
import StardewModCore
import UniformTypeIdentifiers

enum ModListFilter: String, CaseIterable, Identifiable {
    case all
    case enabled
    case attention
    case updates
    case disabled

    var id: Self {
        self
    }

    var label: String {
        switch self {
        case .all:
            "全部"
        case .enabled:
            "启用"
        case .attention:
            "处理"
        case .updates:
            "更新"
        case .disabled:
            "禁用"
        }
    }
}

@MainActor
final class ModLibraryViewModel: ObservableObject {
    @Published private(set) var rootURL: URL
    @Published private(set) var mods: [ModItem] = []
    @Published private(set) var scanErrors: [ModScanError] = []
    @Published var selectedModID: ModItem.ID?
    @Published var searchText = ""
    @Published var selectedFilter: ModListFilter = .all {
        didSet {
            ensureSelectedModMatchesCurrentFilter()
        }
    }
    @Published private(set) var isScanning = false
    @Published private(set) var isInstalling = false
    @Published private(set) var isGameRunning = false
    @Published private(set) var isCheckingUpdates = false
    @Published private(set) var gameConsoleText = ""
    @Published private(set) var updateStatuses: [ModItem.ID: ModUpdateStatus] = [:]
    @Published var installNotice: InstallationNotice?

    private let nexusCategoryResolver = NexusCategoryResolver()
    private let modUpdateChecker = ModUpdateChecker()
    private var categoryLookupTask: Task<Void, Never>?
    private var updateLookupTask: Task<Void, Never>?
    private var gameProcess: Process?
    private var gameOutputPipe: Pipe?
    private var gameErrorPipe: Pipe?

    init(rootURL: URL = DefaultModsLocator.bestGuess()) {
        self.rootURL = rootURL
        refresh()
    }

    var filteredMods: [ModItem] {
        mods.filter { mod in
            let matchesFilter = matchesSelectedFilter(mod)
            let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = normalizedSearch.isEmpty
                || mod.manifest.name.localizedCaseInsensitiveContains(normalizedSearch)
                || mod.manifest.uniqueID.localizedCaseInsensitiveContains(normalizedSearch)
                || mod.relativePath.localizedCaseInsensitiveContains(normalizedSearch)

            return matchesFilter && matchesSearch
        }
    }

    var selectedMod: ModItem? {
        if let selectedModID, let selectedMod = filteredMods.first(where: { $0.id == selectedModID }) {
            return selectedMod
        }
        return filteredMods.first
    }

    var enabledCount: Int {
        mods.filter { $0.status == .enabled }.count
    }

    var disabledCount: Int {
        mods.filter { $0.status == .disabled }.count
    }

    var attentionCount: Int {
        mods.filter { $0.status == .needsAttention }.count
    }

    var updateAvailableCount: Int {
        updateStatuses.values.filter(\.isUpdateAvailable).count
    }

    var smapiExecutableURL: URL {
        rootURL.deletingLastPathComponent()
            .appendingPathComponent("StardewModdingAPI")
            .standardizedFileURL
    }

    func refresh() {
        categoryLookupTask?.cancel()
        updateLookupTask?.cancel()
        isScanning = true
        let result = ModScanner.scan(rootURL: rootURL)
        mods = result.mods
        scanErrors = result.errors

        if selectedModID == nil || !mods.contains(where: { $0.id == selectedModID }) {
            selectedModID = mods.first?.id
        }

        isScanning = false
        resolveNexusCategories(for: result.mods)
        checkForModUpdates(for: result.mods)
        ensureSelectedModMatchesCurrentFilter()
    }

    func updateStatus(for mod: ModItem) -> ModUpdateStatus {
        updateStatuses[mod.id] ?? .notChecked
    }

    func checkForModUpdates() {
        checkForModUpdates(for: mods)
    }

    func count(for filter: ModListFilter) -> Int {
        switch filter {
        case .all:
            mods.count
        case .enabled:
            enabledCount
        case .attention:
            attentionCount
        case .updates:
            updateAvailableCount
        case .disabled:
            disabledCount
        }
    }

    func chooseModsFolder() {
        let panel = NSOpenPanel()
        panel.title = "选择 Stardew Valley Mods 文件夹"
        panel.message = "请选择包含 SMAPI 模组的 Mods 文件夹"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = rootURL

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        rootURL = selectedURL
        selectedModID = nil
        selectedFilter = .all
        refresh()
    }

    func chooseAndInstallMod() {
        let panel = NSOpenPanel()
        panel.title = "安装模组"
        panel.message = "请选择解压后的模组文件夹，或从 Nexus 下载的 .zip 文件"
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip]

        guard panel.runModal() == .OK, let sourceURL = panel.url else {
            return
        }

        installMod(from: sourceURL)
    }

    func chooseAndInstallTranslation() {
        let panel = NSOpenPanel()
        panel.title = "安装模组翻译"
        panel.message = "请选择翻译文件夹、单个翻译文件，或 .zip 翻译包"
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip, .json, .plainText, .data]

        guard panel.runModal() == .OK, let sourceURL = panel.url else {
            return
        }

        installTranslation(from: sourceURL)
    }

    func installMod(from sourceURL: URL) {
        let rootURL = rootURL
        isInstalling = true

        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try ModInstaller.install(sourceURL: sourceURL, into: rootURL)
                }.value

                refresh()
                installNotice = InstallationNotice(
                    title: "安装完成",
                    message: installSummary(for: result)
                )
            } catch {
                installNotice = InstallationNotice(
                    title: "安装失败",
                    message: error.localizedDescription
                )
            }

            isInstalling = false
        }
    }

    func installTranslation(from sourceURL: URL) {
        let rootURL = rootURL
        let targetModURL = selectedMod?.folderURL
        isInstalling = true

        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try ModInstaller.installTranslation(
                        sourceURL: sourceURL,
                        into: rootURL,
                        targetModURL: targetModURL
                    )
                }.value

                refresh()
                installNotice = InstallationNotice(
                    title: "翻译安装完成",
                    message: translationSummary(for: result)
                )
            } catch {
                installNotice = InstallationNotice(
                    title: "翻译安装失败",
                    message: error.localizedDescription
                )
            }

            isInstalling = false
        }
    }

    func revealSelectedModInFinder() {
        guard let selectedMod else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([selectedMod.folderURL])
    }

    func launchGame() {
        let executableURL = smapiExecutableURL
        guard FileManager.default.fileExists(atPath: executableURL.path) else {
            appendGameConsoleLine("启动失败：找不到 StardewModdingAPI：\(executableURL.path)")
            installNotice = InstallationNotice(
                title: "启动失败",
                message: "找不到 StardewModdingAPI：\(executableURL.path)"
            )
            return
        }

        do {
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.executableURL = executableURL
            process.currentDirectoryURL = executableURL.deletingLastPathComponent()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty else {
                    return
                }

                let text = String(decoding: data, as: UTF8.self)
                Task { @MainActor [weak self] in
                    self?.appendGameConsole(text)
                }
            }

            errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty else {
                    return
                }

                let text = String(decoding: data, as: UTF8.self)
                Task { @MainActor [weak self] in
                    self?.appendGameConsole(text)
                }
            }

            process.terminationHandler = { [weak self] process in
                let status = process.terminationStatus
                Task { @MainActor [weak self] in
                    self?.finishGameProcess(status: status)
                }
            }

            gameProcess = process
            gameOutputPipe = outputPipe
            gameErrorPipe = errorPipe
            isGameRunning = true
            resetGameConsole(for: executableURL)
            try process.run()

            installNotice = InstallationNotice(
                title: "正在启动游戏",
                message: "已通过 StardewModdingAPI 启动：\(executableURL.path)"
            )
        } catch {
            appendGameConsoleLine("启动失败：\(error.localizedDescription)")
            installNotice = InstallationNotice(
                title: "启动失败",
                message: error.localizedDescription
            )
            finishGameProcess(status: nil)
        }
    }

    func stopGame() {
        guard let gameProcess else {
            appendGameConsoleLine("没有正在运行的游戏进程。")
            isGameRunning = false
            return
        }

        guard gameProcess.isRunning else {
            finishGameProcess(status: gameProcess.terminationStatus)
            return
        }

        appendGameConsoleLine("\n正在停止进程：\(gameProcess.processIdentifier)")
        gameProcess.terminate()
    }

    func clearGameConsole() {
        gameConsoleText = ""
    }

    private func resetGameConsole(for executableURL: URL) {
        let workingDirectory = executableURL.deletingLastPathComponent().path
        gameConsoleText = """
        $ cd \(shellQuoted(workingDirectory))
        $ ./\(executableURL.lastPathComponent)

        """
    }

    private func appendGameConsoleLine(_ line: String) {
        appendGameConsole(line + "\n")
    }

    private func appendGameConsole(_ text: String) {
        gameConsoleText += text

        let maximumConsoleLength = 120_000
        if gameConsoleText.count > maximumConsoleLength {
            gameConsoleText = String(gameConsoleText.suffix(maximumConsoleLength))
        }
    }

    private func finishGameProcess(status: Int32?) {
        gameOutputPipe?.fileHandleForReading.readabilityHandler = nil
        gameErrorPipe?.fileHandleForReading.readabilityHandler = nil
        gameOutputPipe = nil
        gameErrorPipe = nil
        gameProcess = nil
        isGameRunning = false

        if let status {
            appendGameConsoleLine("\n进程已退出，退出码：\(status)")
        }
    }

    private func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func installSummary(for result: ModInstallResult) -> String {
        if result.replacedCount > 0 {
            return "已安装 \(result.installedCount) 个模组，并先删除后替换了 \(result.replacedCount) 个已有模组。"
        }

        return "已安装 \(result.installedCount) 个模组。"
    }

    private func translationSummary(for result: ModTranslationInstallResult) -> String {
        "已安装 \(result.installedCount) 个翻译文件，其中新增 \(result.createdCount) 个，覆盖 \(result.overwrittenCount) 个。"
    }

    private func resolveNexusCategories(for scannedMods: [ModItem]) {
        let nexusModIDs = Set(scannedMods.compactMap(\.manifest.nexusModID))
        guard !nexusModIDs.isEmpty else {
            return
        }

        categoryLookupTask = Task { [nexusCategoryResolver] in
            let resolvedCategories = await nexusCategoryResolver.categories(for: nexusModIDs)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                mods = mods.map { mod in
                    guard let nexusModID = mod.manifest.nexusModID else {
                        return mod
                    }

                    return mod.replacingCategory(resolvedCategories[nexusModID] ?? "未分类")
                }
            }
        }
    }

    private func matchesSelectedFilter(_ mod: ModItem) -> Bool {
        switch selectedFilter {
        case .all:
            true
        case .enabled:
            mod.status == .enabled
        case .attention:
            mod.status == .needsAttention
        case .updates:
            updateStatuses[mod.id]?.isUpdateAvailable == true
        case .disabled:
            mod.status == .disabled
        }
    }

    private func ensureSelectedModMatchesCurrentFilter() {
        if let selectedModID, filteredMods.contains(where: { $0.id == selectedModID }) {
            return
        }

        selectedModID = filteredMods.first?.id
    }

    private func checkForModUpdates(for scannedMods: [ModItem]) {
        updateLookupTask?.cancel()

        let currentIDs = Set(scannedMods.map(\.id))
        updateStatuses = updateStatuses.filter { currentIDs.contains($0.key) }

        guard !scannedMods.isEmpty else {
            isCheckingUpdates = false
            return
        }

        for mod in scannedMods {
            updateStatuses[mod.id] = .checking
        }
        isCheckingUpdates = true

        updateLookupTask = Task { [modUpdateChecker] in
            let statuses = await modUpdateChecker.updateStatuses(for: scannedMods)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                for mod in scannedMods {
                    updateStatuses[mod.id] = statuses[mod.id] ?? .current
                }
                isCheckingUpdates = false
                ensureSelectedModMatchesCurrentFilter()
            }
        }
    }
}

struct InstallationNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private extension ModItem {
    func replacingCategory(_ category: String) -> ModItem {
        ModItem(
            manifest: manifest,
            folderURL: folderURL,
            relativePath: relativePath,
            category: category,
            isDisabled: isDisabled,
            missingRequiredDependencies: missingRequiredDependencies,
            missingOptionalDependencies: missingOptionalDependencies,
            isDuplicateUniqueID: isDuplicateUniqueID
        )
    }
}

enum DefaultModsLocator {
    static func bestGuess() -> URL {
        let steamModsPath = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/Steam/steamapps/common/Stardew Valley/Contents/MacOS/Mods")

        if FileManager.default.fileExists(atPath: steamModsPath.path) {
            return steamModsPath
        }

        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/Steam/steamapps/common/Stardew Valley/Contents/MacOS/Mods")
    }
}
