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
    @Published private(set) var isChangingModState = false
    @Published private(set) var isGameRunning = false
    @Published private(set) var isCheckingUpdates = false
    @Published private(set) var gameConsoleText = ""
    @Published private(set) var updateStatuses: [ModItem.ID: ModUpdateStatus] = [:]
    @Published var installNotice: InstallationNotice?

    private let modUpdateChecker = ModUpdateChecker()
    private let folderStore: ModsFolderStore
    private let gameProcessController: GameProcessController
    private var updateLookupTask: Task<Void, Never>?
    private var gameConsoleLanguage: AppLanguage = .simplifiedChinese

    init(
        rootURL: URL? = nil,
        folderStore: ModsFolderStore = ModsFolderStore(),
        gameProcessController: GameProcessController = GameProcessController()
    ) {
        self.folderStore = folderStore
        self.gameProcessController = gameProcessController
        self.rootURL = rootURL ?? folderStore.load() ?? DefaultModsLocator.bestGuess()
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
        updateLookupTask?.cancel()
        isScanning = true
        let result = ModScanner.scan(rootURL: rootURL)
        mods = result.mods
        scanErrors = result.errors

        if selectedModID == nil || !mods.contains(where: { $0.id == selectedModID }) {
            selectedModID = mods.first?.id
        }

        isScanning = false
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

    func chooseModsFolder(language: AppLanguage) {
        let strings = AppStrings(language: language)
        let panel = NSOpenPanel()
        panel.title = strings.chooseModsFolderTitle
        panel.message = strings.chooseModsFolderMessage
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = rootURL

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        rootURL = selectedURL
        folderStore.save(selectedURL)
        selectedModID = nil
        selectedFilter = .all
        refresh()
    }

    func chooseAndInstallMod(language: AppLanguage) {
        let strings = AppStrings(language: language)
        let panel = NSOpenPanel()
        panel.title = strings.installMod
        panel.message = strings.installModPanelMessage
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip]

        guard panel.runModal() == .OK, let sourceURL = panel.url else {
            return
        }

        installMod(from: sourceURL, language: language)
    }

    func chooseAndInstallTranslation(language: AppLanguage) {
        let strings = AppStrings(language: language)
        let panel = NSOpenPanel()
        panel.title = strings.installTranslationTitle
        panel.message = strings.installTranslationPanelMessage
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip, .json, .plainText, .data]

        guard panel.runModal() == .OK, let sourceURL = panel.url else {
            return
        }

        installTranslation(from: sourceURL, language: language)
    }

    func installMod(from sourceURL: URL, language: AppLanguage) {
        let rootURL = rootURL
        let strings = AppStrings(language: language)
        isInstalling = true

        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try ModInstaller.install(sourceURL: sourceURL, into: rootURL)
                }.value

                refresh()
                installNotice = InstallationNotice(
                    title: strings.installFinishedTitle,
                    message: strings.installedSummary(
                        installedCount: result.installedCount,
                        replacedCount: result.replacedCount
                    )
                )
            } catch {
                installNotice = InstallationNotice(
                    title: strings.installFailedTitle,
                    message: strings.errorDescription(error)
                )
            }

            isInstalling = false
        }
    }

    func installTranslation(from sourceURL: URL, language: AppLanguage) {
        let rootURL = rootURL
        let targetModURL = selectedMod?.folderURL
        let strings = AppStrings(language: language)
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
                    title: strings.translationInstallFinishedTitle,
                    message: strings.translationSummary(
                        installedCount: result.installedCount,
                        createdCount: result.createdCount,
                        overwrittenCount: result.overwrittenCount
                    )
                )
            } catch {
                installNotice = InstallationNotice(
                    title: strings.translationInstallFailedTitle,
                    message: strings.errorDescription(error)
                )
            }

            isInstalling = false
        }
    }

    func revealSelectedModInFinder() {
        guard let selectedMod else {
            return
        }
        revealModInFinder(selectedMod)
    }

    func revealModInFinder(_ mod: ModItem) {
        NSWorkspace.shared.activateFileViewerSelecting([mod.folderURL])
    }

    func toggleSelectedModEnabled(language: AppLanguage) {
        guard let selectedMod else {
            return
        }

        setMod(selectedMod, enabled: selectedMod.isDisabled, language: language)
    }

    func setMod(_ mod: ModItem, enabled isEnabled: Bool, language: AppLanguage) {
        guard !isChangingModState else {
            return
        }

        let strings = AppStrings(language: language)
        isChangingModState = true
        defer {
            isChangingModState = false
        }

        do {
            let result = try ModStateController.setEnabled(isEnabled, for: mod)
            let uniqueID = mod.manifest.uniqueID
            refresh()
            selectedModID = mods.first { candidate in
                candidate.folderURL.standardizedFileURL == result.destinationURL.standardizedFileURL
            }?.id ?? mods.first { candidate in
                candidate.manifest.uniqueID.caseInsensitiveCompare(uniqueID) == .orderedSame
            }?.id
            ensureSelectedModMatchesCurrentFilter()

            installNotice = InstallationNotice(
                title: isEnabled ? strings.modEnabledTitle : strings.modDisabledTitle,
                message: "\(mod.manifest.name)\n\(result.destinationURL.lastPathComponent)"
            )
        } catch {
            installNotice = InstallationNotice(
                title: isEnabled ? strings.enableFailedTitle : strings.disableFailedTitle,
                message: strings.errorDescription(error)
            )
        }
    }

    func launchGame(language: AppLanguage) {
        let strings = AppStrings(language: language)
        gameConsoleLanguage = language
        let executableURL = smapiExecutableURL
        guard FileManager.default.fileExists(atPath: executableURL.path) else {
            let message = strings.smapiNotFound(executableURL.path)
            appendGameConsoleLine(strings.launchFailed(message))
            installNotice = InstallationNotice(
                title: strings.launchFailedTitle,
                message: message
            )
            return
        }

        do {
            isGameRunning = true
            resetGameConsole(for: executableURL)
            try gameProcessController.launch(
                executableURL: executableURL,
                onOutput: { [weak self] text in
                    self?.appendGameConsole(text)
                },
                onTermination: { [weak self] status in
                    self?.finishGameProcess(status: status)
                }
            )

            installNotice = InstallationNotice(
                title: strings.launchingGameTitle,
                message: strings.launchedGame(executableURL.path)
            )
        } catch {
            appendGameConsoleLine(strings.launchFailed(strings.errorDescription(error)))
            installNotice = InstallationNotice(
                title: strings.launchFailedTitle,
                message: strings.errorDescription(error)
            )
            finishGameProcess(status: nil)
        }
    }

    func stopGame(language: AppLanguage) {
        let strings = AppStrings(language: language)
        gameConsoleLanguage = language
        guard gameProcessController.isRunning else {
            appendGameConsoleLine(strings.noRunningGameProcess)
            isGameRunning = false
            return
        }

        if let processIdentifier = gameProcessController.processIdentifier {
            appendGameConsoleLine("\n\(strings.stoppingProcess(processIdentifier))")
        }
        gameProcessController.stop()
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
        isGameRunning = false

        if let status {
            let strings = AppStrings(language: gameConsoleLanguage)
            appendGameConsoleLine("\n\(strings.processExited(status: status))")
        }
    }

    private func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
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
