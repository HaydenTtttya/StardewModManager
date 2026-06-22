import Foundation
import StardewModCore

struct AppStrings: Sendable {
    let language: AppLanguage

    var settingsTitle: String {
        switch language {
        case .simplifiedChinese:
            "设置"
        case .english:
            "Settings"
        }
    }

    var settingsGeneralSection: String {
        switch language {
        case .simplifiedChinese:
            "通用"
        case .english:
            "General"
        }
    }

    var languageLabel: String {
        switch language {
        case .simplifiedChinese:
            "语言"
        case .english:
            "Language"
        }
    }

    var languageHelp: String {
        switch language {
        case .simplifiedChinese:
            "切换后界面会立即使用所选语言。"
        case .english:
            "The interface updates immediately after you choose a language."
        }
    }

    var installMod: String {
        switch language {
        case .simplifiedChinese:
            "安装模组"
        case .english:
            "Install Mod"
        }
    }

    var installModHelp: String {
        switch language {
        case .simplifiedChinese:
            "安装文件夹或 zip 模组包"
        case .english:
            "Install a folder or zip mod package"
        }
    }

    var installTranslation: String {
        switch language {
        case .simplifiedChinese:
            "安装翻译"
        case .english:
            "Install Translation"
        }
    }

    var installTranslationHelp: String {
        switch language {
        case .simplifiedChinese:
            "安装翻译文件夹、翻译文件或 zip 翻译包"
        case .english:
            "Install a translation folder, file, or zip package"
        }
    }

    var stopProcess: String {
        switch language {
        case .simplifiedChinese:
            "停止进程"
        case .english:
            "Stop Process"
        }
    }

    var startGame: String {
        switch language {
        case .simplifiedChinese:
            "启动游戏"
        case .english:
            "Start Game"
        }
    }

    var startGameHelp: String {
        switch language {
        case .simplifiedChinese:
            "通过 StardewModdingAPI 启动游戏"
        case .english:
            "Launch the game through StardewModdingAPI"
        }
    }

    var stopGameHelp: String {
        switch language {
        case .simplifiedChinese:
            "停止当前 StardewModdingAPI 进程"
        case .english:
            "Stop the current StardewModdingAPI process"
        }
    }

    var chooseDirectory: String {
        switch language {
        case .simplifiedChinese:
            "选择目录"
        case .english:
            "Choose Folder"
        }
    }

    var chooseModsFolderHelp: String {
        switch language {
        case .simplifiedChinese:
            "选择 Mods 文件夹"
        case .english:
            "Choose the Mods folder"
        }
    }

    var refresh: String {
        switch language {
        case .simplifiedChinese:
            "刷新"
        case .english:
            "Refresh"
        }
    }

    var refreshHelp: String {
        switch language {
        case .simplifiedChinese:
            "重新扫描"
        case .english:
            "Scan again"
        }
    }

    var checkUpdates: String {
        switch language {
        case .simplifiedChinese:
            "检查更新"
        case .english:
            "Check Updates"
        }
    }

    var checkUpdatesHelp: String {
        switch language {
        case .simplifiedChinese:
            "检查已安装模组是否有新版本"
        case .english:
            "Check installed mods for new versions"
        }
    }

    var enableMod: String {
        switch language {
        case .simplifiedChinese:
            "启用模组"
        case .english:
            "Enable Mod"
        }
    }

    var disableMod: String {
        switch language {
        case .simplifiedChinese:
            "禁用模组"
        case .english:
            "Disable Mod"
        }
    }

    var enableSelectedModHelp: String {
        switch language {
        case .simplifiedChinese:
            "启用选中的模组"
        case .english:
            "Enable the selected mod"
        }
    }

    var disableSelectedModHelp: String {
        switch language {
        case .simplifiedChinese:
            "禁用选中的模组"
        case .english:
            "Disable the selected mod"
        }
    }

    var revealInFinder: String {
        switch language {
        case .simplifiedChinese:
            "在 Finder 中显示"
        case .english:
            "Show in Finder"
        }
    }

    var revealInFinderHelp: String {
        switch language {
        case .simplifiedChinese:
            "在 Finder 中显示选中的模组"
        case .english:
            "Show the selected mod in Finder"
        }
    }

    var ok: String {
        switch language {
        case .simplifiedChinese:
            "好"
        case .english:
            "OK"
        }
    }

    var gameConsole: String {
        switch language {
        case .simplifiedChinese:
            "游戏终端"
        case .english:
            "Game Console"
        }
    }

    var running: String {
        switch language {
        case .simplifiedChinese:
            "运行中"
        case .english:
            "Running"
        }
    }

    var clear: String {
        switch language {
        case .simplifiedChinese:
            "清空"
        case .english:
            "Clear"
        }
    }

    var gameConsolePlaceholder: String {
        switch language {
        case .simplifiedChinese:
            "启动游戏后，SMAPI 的加载日志会显示在这里。"
        case .english:
            "After you start the game, SMAPI loading logs will appear here."
        }
    }

    var searchModsPrompt: String {
        switch language {
        case .simplifiedChinese:
            "搜索模组"
        case .english:
            "Search mods"
        }
    }

    var updateCompact: String {
        switch language {
        case .simplifiedChinese:
            "更新"
        case .english:
            "Update"
        }
    }

    var noMods: String {
        switch language {
        case .simplifiedChinese:
            "没有可显示的模组"
        case .english:
            "No mods to show"
        }
    }

    var modLibrary: String {
        switch language {
        case .simplifiedChinese:
            "模组资料库"
        case .english:
            "Mod Library"
        }
    }

    var moreActions: String {
        switch language {
        case .simplifiedChinese:
            "更多操作"
        case .english:
            "More Actions"
        }
    }

    var showConsole: String {
        switch language {
        case .simplifiedChinese:
            "展开游戏终端"
        case .english:
            "Show Game Console"
        }
    }

    var hideConsole: String {
        switch language {
        case .simplifiedChinese:
            "收起游戏终端"
        case .english:
            "Hide Game Console"
        }
    }

    var modInformation: String {
        switch language {
        case .simplifiedChinese:
            "模组信息"
        case .english:
            "Mod Information"
        }
    }

    var enabledToggle: String {
        switch language {
        case .simplifiedChinese:
            "启用"
        case .english:
            "Enabled"
        }
    }

    var enableThisModHelp: String {
        switch language {
        case .simplifiedChinese:
            "启用此模组"
        case .english:
            "Enable this mod"
        }
    }

    var disableThisModHelp: String {
        switch language {
        case .simplifiedChinese:
            "禁用此模组"
        case .english:
            "Disable this mod"
        }
    }

    var modDisabledIssue: String {
        switch language {
        case .simplifiedChinese:
            "此模组处于禁用状态"
        case .english:
            "This mod is disabled"
        }
    }

    var duplicateUniqueIDIssue: String {
        switch language {
        case .simplifiedChinese:
            "检测到重复 UniqueID"
        case .english:
            "Duplicate UniqueID detected"
        }
    }

    var checkingUpdates: String {
        switch language {
        case .simplifiedChinese:
            "正在检查更新..."
        case .english:
            "Checking for updates..."
        }
    }

    var openDownloadPage: String {
        switch language {
        case .simplifiedChinese:
            "打开下载页"
        case .english:
            "Open Download Page"
        }
    }

    var metadataType: String {
        switch language {
        case .simplifiedChinese:
            "类型"
        case .english:
            "Type"
        }
    }

    var metadataPath: String {
        switch language {
        case .simplifiedChinese:
            "路径"
        case .english:
            "Path"
        }
    }

    var metadataContentPackTarget: String {
        switch language {
        case .simplifiedChinese:
            "内容包目标"
        case .english:
            "Content Pack Target"
        }
    }

    var metadataGameVersion: String {
        switch language {
        case .simplifiedChinese:
            "游戏版本"
        case .english:
            "Game Version"
        }
    }

    var dependencies: String {
        switch language {
        case .simplifiedChinese:
            "依赖"
        case .english:
            "Dependencies"
        }
    }

    var required: String {
        switch language {
        case .simplifiedChinese:
            "必需"
        case .english:
            "Required"
        }
    }

    var optional: String {
        switch language {
        case .simplifiedChinese:
            "可选"
        case .english:
            "Optional"
        }
    }

    var updateSources: String {
        switch language {
        case .simplifiedChinese:
            "更新源"
        case .english:
            "Update Sources"
        }
    }

    var description: String {
        switch language {
        case .simplifiedChinese:
            "说明"
        case .english:
            "Description"
        }
    }

    var chooseModsFolderTitle: String {
        switch language {
        case .simplifiedChinese:
            "选择 Stardew Valley Mods 文件夹"
        case .english:
            "Choose Stardew Valley Mods Folder"
        }
    }

    var chooseModsFolderMessage: String {
        switch language {
        case .simplifiedChinese:
            "请选择包含 SMAPI 模组的 Mods 文件夹"
        case .english:
            "Choose the Mods folder that contains your SMAPI mods"
        }
    }

    var installModPanelMessage: String {
        switch language {
        case .simplifiedChinese:
            "请选择解压后的模组文件夹，或从 Nexus 下载的 .zip 文件"
        case .english:
            "Choose an extracted mod folder or a .zip file downloaded from Nexus"
        }
    }

    var installTranslationTitle: String {
        switch language {
        case .simplifiedChinese:
            "安装模组翻译"
        case .english:
            "Install Mod Translation"
        }
    }

    var installTranslationPanelMessage: String {
        switch language {
        case .simplifiedChinese:
            "请选择翻译文件夹、单个翻译文件，或 .zip 翻译包"
        case .english:
            "Choose a translation folder, a single translation file, or a .zip package"
        }
    }

    var installFinishedTitle: String {
        switch language {
        case .simplifiedChinese:
            "安装完成"
        case .english:
            "Install Complete"
        }
    }

    var installFailedTitle: String {
        switch language {
        case .simplifiedChinese:
            "安装失败"
        case .english:
            "Install Failed"
        }
    }

    var translationInstallFinishedTitle: String {
        switch language {
        case .simplifiedChinese:
            "翻译安装完成"
        case .english:
            "Translation Installed"
        }
    }

    var translationInstallFailedTitle: String {
        switch language {
        case .simplifiedChinese:
            "翻译安装失败"
        case .english:
            "Translation Install Failed"
        }
    }

    var modEnabledTitle: String {
        switch language {
        case .simplifiedChinese:
            "已启用模组"
        case .english:
            "Mod Enabled"
        }
    }

    var modDisabledTitle: String {
        switch language {
        case .simplifiedChinese:
            "已禁用模组"
        case .english:
            "Mod Disabled"
        }
    }

    var enableFailedTitle: String {
        switch language {
        case .simplifiedChinese:
            "启用失败"
        case .english:
            "Enable Failed"
        }
    }

    var disableFailedTitle: String {
        switch language {
        case .simplifiedChinese:
            "禁用失败"
        case .english:
            "Disable Failed"
        }
    }

    var launchFailedTitle: String {
        switch language {
        case .simplifiedChinese:
            "启动失败"
        case .english:
            "Launch Failed"
        }
    }

    var launchingGameTitle: String {
        switch language {
        case .simplifiedChinese:
            "正在启动游戏"
        case .english:
            "Starting Game"
        }
    }

    var noRunningGameProcess: String {
        switch language {
        case .simplifiedChinese:
            "没有正在运行的游戏进程。"
        case .english:
            "No game process is running."
        }
    }

    func filterLabel(_ filter: ModListFilter) -> String {
        switch (filter, language) {
        case (.all, .simplifiedChinese):
            "全部"
        case (.all, .english):
            "All"
        case (.enabled, .simplifiedChinese):
            "启用"
        case (.enabled, .english):
            "Enabled"
        case (.attention, .simplifiedChinese):
            "处理"
        case (.attention, .english):
            "Needs Work"
        case (.updates, .simplifiedChinese):
            "更新"
        case (.updates, .english):
            "Updates"
        case (.disabled, .simplifiedChinese):
            "禁用"
        case (.disabled, .english):
            "Disabled"
        }
    }

    func modCount(_ count: Int) -> String {
        switch language {
        case .simplifiedChinese:
            "共 \(count) 个模组"
        case .english:
            count == 1 ? "1 mod" : "\(count) mods"
        }
    }

    func filterHelp(_ filter: ModListFilter) -> String {
        switch language {
        case .simplifiedChinese:
            "筛选\(filterLabel(filter))模组"
        case .english:
            "Show \(filterLabel(filter).lowercased()) mods"
        }
    }

    func modKindLabel(_ kind: ModKind) -> String {
        switch (kind, language) {
        case (.codeMod, .simplifiedChinese):
            "代码模组"
        case (.codeMod, .english):
            "Code Mod"
        case (.contentPack, .simplifiedChinese):
            "内容包"
        case (.contentPack, .english):
            "Content Pack"
        }
    }

    func modStatusLabel(_ status: ModStatus) -> String {
        switch (status, language) {
        case (.enabled, .simplifiedChinese):
            "已启用"
        case (.enabled, .english):
            "Enabled"
        case (.disabled, .simplifiedChinese):
            "已禁用"
        case (.disabled, .english):
            "Disabled"
        case (.needsAttention, .simplifiedChinese):
            "需处理"
        case (.needsAttention, .english):
            "Needs Work"
        }
    }

    func authorName(_ author: String?) -> String {
        if let author, !author.isEmpty {
            return author
        }

        switch language {
        case .simplifiedChinese:
            return "未知作者"
        case .english:
            return "Unknown Author"
        }
    }

    func updateStatusShortLabel(_ status: ModUpdateStatus) -> String {
        switch (status, language) {
        case (.notChecked, .simplifiedChinese):
            "未检查"
        case (.notChecked, .english):
            "Not Checked"
        case (.checking, .simplifiedChinese):
            "检查中"
        case (.checking, .english):
            "Checking"
        case (.current, .simplifiedChinese):
            "最新"
        case (.current, .english):
            "Current"
        case (.updateAvailable, .simplifiedChinese):
            "可更新"
        case (.updateAvailable, .english):
            "Update Available"
        case (.failed, .simplifiedChinese):
            "检查失败"
        case (.failed, .english):
            "Check Failed"
        }
    }

    func updateAvailable(version: String) -> String {
        switch language {
        case .simplifiedChinese:
            "可更新到 \(version)"
        case .english:
            "Update to \(version)"
        }
    }

    func scanErrorCount(_ count: Int) -> String {
        switch language {
        case .simplifiedChinese:
            "\(count) 个 manifest 读取失败"
        case .english:
            count == 1 ? "1 manifest failed to load" : "\(count) manifests failed to load"
        }
    }

    func missingRequiredDependency(_ uniqueID: String) -> String {
        switch language {
        case .simplifiedChinese:
            "缺少必需依赖：\(uniqueID)"
        case .english:
            "Missing required dependency: \(uniqueID)"
        }
    }

    func foundNewVersion(version: String, currentVersion: String) -> String {
        switch language {
        case .simplifiedChinese:
            "发现新版本：\(version)（当前 \(currentVersion)）"
        case .english:
            "New version found: \(version) (current \(currentVersion))"
        }
    }

    func updateCheckFailed(_ message: String) -> String {
        switch language {
        case .simplifiedChinese:
            "更新检查失败：\(localizedKnownMessage(message))"
        case .english:
            "Update check failed: \(localizedKnownMessage(message))"
        }
    }

    func installedSummary(installedCount: Int, replacedCount: Int) -> String {
        switch language {
        case .simplifiedChinese:
            if replacedCount > 0 {
                return "已安装 \(installedCount) 个模组，并先删除后替换了 \(replacedCount) 个已有模组。"
            }
            return "已安装 \(installedCount) 个模组。"
        case .english:
            if replacedCount > 0 {
                return "Installed \(installedCount) \(plural("mod", installedCount)) and replaced \(replacedCount) existing \(plural("mod", replacedCount))."
            }
            return "Installed \(installedCount) \(plural("mod", installedCount))."
        }
    }

    func translationSummary(installedCount: Int, createdCount: Int, overwrittenCount: Int) -> String {
        switch language {
        case .simplifiedChinese:
            "已安装 \(installedCount) 个翻译文件，其中新增 \(createdCount) 个，覆盖 \(overwrittenCount) 个。"
        case .english:
            "Installed \(installedCount) translation \(plural("file", installedCount)): \(createdCount) created, \(overwrittenCount) overwritten."
        }
    }

    func smapiNotFound(_ path: String) -> String {
        switch language {
        case .simplifiedChinese:
            "找不到 StardewModdingAPI：\(path)"
        case .english:
            "Could not find StardewModdingAPI: \(path)"
        }
    }

    func launchFailed(_ message: String) -> String {
        switch language {
        case .simplifiedChinese:
            "启动失败：\(localizedKnownMessage(message))"
        case .english:
            "Launch failed: \(localizedKnownMessage(message))"
        }
    }

    func launchedGame(_ path: String) -> String {
        switch language {
        case .simplifiedChinese:
            "已通过 StardewModdingAPI 启动：\(path)"
        case .english:
            "Started through StardewModdingAPI: \(path)"
        }
    }

    func stoppingProcess(_ processIdentifier: Int32) -> String {
        switch language {
        case .simplifiedChinese:
            "正在停止进程：\(processIdentifier)"
        case .english:
            "Stopping process: \(processIdentifier)"
        }
    }

    func processExited(status: Int32) -> String {
        switch language {
        case .simplifiedChinese:
            "进程已退出，退出码：\(status)"
        case .english:
            "Process exited with code \(status)"
        }
    }

    func errorDescription(_ error: Error) -> String {
        switch error {
        case let error as ModInstallError:
            modInstallErrorDescription(error)
        case let error as ModStateChangeError:
            modStateChangeErrorDescription(error)
        default:
            localizedKnownMessage(error.localizedDescription)
        }
    }

    private func modInstallErrorDescription(_ error: ModInstallError) -> String {
        switch (error, language) {
        case (.sourceNotFound(let url), .simplifiedChinese):
            "找不到要安装的模组：\(url.path)"
        case (.sourceNotFound(let url), .english):
            "Could not find the mod to install: \(url.path)"
        case (.noManifestFound(let url), .simplifiedChinese):
            "没有在所选项目中找到 manifest.json：\(url.lastPathComponent)"
        case (.noManifestFound(let url), .english):
            "No manifest.json was found in the selected item: \(url.lastPathComponent)"
        case (.noTranslationFilesFound(let url), .simplifiedChinese):
            "没有在所选项目中找到可安装的翻译文件：\(url.lastPathComponent)"
        case (.noTranslationFilesFound(let url), .english):
            "No installable translation files were found in the selected item: \(url.lastPathComponent)"
        case (.noTranslationTargetFound, .simplifiedChinese):
            "没有找到可以安装翻译的目标文件。请先选中目标模组，或确认翻译包目录结构和已安装模组一致。"
        case (.noTranslationTargetFound, .english):
            "No target files were found for the translation. Select the target mod first, or check that the translation package matches an installed mod."
        case (.unsupportedArchive(let url), .simplifiedChinese):
            "暂不支持该压缩包格式：\(url.lastPathComponent)"
        case (.unsupportedArchive(let url), .english):
            "This archive format is not supported yet: \(url.lastPathComponent)"
        case (.archiveExtractionFailed(let url, let status), .simplifiedChinese):
            "解压失败：\(url.lastPathComponent)（退出码 \(status)）"
        case (.archiveExtractionFailed(let url, let status), .english):
            "Extraction failed: \(url.lastPathComponent) (exit code \(status))"
        case (.sourceInsideModsFolder(let url), .simplifiedChinese):
            "不能从当前 Mods 文件夹内部安装：\(url.lastPathComponent)"
        case (.sourceInsideModsFolder(let url), .english):
            "Cannot install from inside the current Mods folder: \(url.lastPathComponent)"
        }
    }

    private func modStateChangeErrorDescription(_ error: ModStateChangeError) -> String {
        switch (error, language) {
        case (.sourceNotFound(let url), .simplifiedChinese):
            "找不到模组文件夹：\(url.path)"
        case (.sourceNotFound(let url), .english):
            "Could not find the mod folder: \(url.path)"
        case (.disabledByParentDirectory(let url), .simplifiedChinese):
            "此模组是被上级目录禁用的，无法只启用单个模组：\(url.path)"
        case (.disabledByParentDirectory(let url), .english):
            "This mod is disabled by a parent folder, so a single child mod cannot be enabled: \(url.path)"
        }
    }

    private func localizedKnownMessage(_ message: String) -> String {
        switch (message, language) {
        case ("modUpdate.requestFailed", .simplifiedChinese):
            "SMAPI 更新检查请求失败"
        case ("modUpdate.requestFailed", .english):
            "SMAPI update check request failed"
        case ("SMAPI 更新检查请求失败", .english):
            "SMAPI update check request failed"
        default:
            message
        }
    }

    private func plural(_ word: String, _ count: Int) -> String {
        count == 1 ? word : "\(word)s"
    }
}
