import StardewModCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailPaneView()
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    library.chooseAndInstallMod(language: settings.language)
                } label: {
                    Label(strings.installMod, systemImage: "square.and.arrow.down")
                }
                .disabled(library.isInstalling)
                .help(strings.installModHelp)

                Button {
                    library.chooseAndInstallTranslation(language: settings.language)
                } label: {
                    Label(strings.installTranslation, systemImage: "globe.asia.australia")
                }
                .disabled(library.isInstalling)
                .help(strings.installTranslationHelp)

                Button {
                    if library.isGameRunning {
                        library.stopGame(language: settings.language)
                    } else {
                        library.launchGame(language: settings.language)
                    }
                } label: {
                    if library.isGameRunning {
                        Label(strings.stopProcess, systemImage: "stop.fill")
                    } else {
                        Label(strings.startGame, systemImage: "play.fill")
                    }
                }
                .disabled(library.isInstalling)
                .help(library.isGameRunning ? strings.stopGameHelp : strings.startGameHelp)

                Button {
                    library.chooseModsFolder(language: settings.language)
                } label: {
                    Label(strings.chooseDirectory, systemImage: "folder")
                }
                .help(strings.chooseModsFolderHelp)

                Button {
                    library.refresh()
                } label: {
                    Label(strings.refresh, systemImage: "arrow.clockwise")
                }
                .help(strings.refreshHelp)

                Button {
                    library.checkForModUpdates()
                } label: {
                    Label(strings.checkUpdates, systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(library.isCheckingUpdates || library.mods.isEmpty)
                .help(strings.checkUpdatesHelp)

                Button {
                    library.toggleSelectedModEnabled(language: settings.language)
                } label: {
                    if library.selectedMod?.isDisabled == true {
                        Label(strings.enableMod, systemImage: "power.circle")
                    } else {
                        Label(strings.disableMod, systemImage: "pause.circle")
                    }
                }
                .disabled(library.selectedMod == nil || library.isInstalling || library.isChangingModState)
                .help(library.selectedMod?.isDisabled == true ? strings.enableSelectedModHelp : strings.disableSelectedModHelp)

                Button {
                    library.revealSelectedModInFinder()
                } label: {
                    Label(strings.revealInFinder, systemImage: "magnifyingglass")
                }
                .disabled(library.selectedMod == nil)
                .help(strings.revealInFinderHelp)
            }
        }
        .alert(item: $library.installNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text(strings.ok))
            )
        }
    }
}

private struct DetailPaneView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let mod = library.selectedMod {
                    ModDetailView(
                        mod: mod,
                        updateStatus: library.updateStatus(for: mod),
                        isChangingState: library.isChangingModState,
                        onSetEnabled: { isEnabled in
                            library.setMod(mod, enabled: isEnabled, language: settings.language)
                        }
                    )
                } else {
                    EmptyStateView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            GameConsoleView()
                .frame(minHeight: 180, idealHeight: 240, maxHeight: 300)
        }
    }
}

private struct GameConsoleView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "terminal")
                    .foregroundStyle(.secondary)
                Text(strings.gameConsole)
                    .font(.headline)

                if library.isGameRunning {
                    ProgressView()
                        .controlSize(.small)
                    Text(strings.running)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(strings.clear) {
                    library.clearGameConsole()
                }
                .disabled(library.gameConsoleText.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    Text(attributedConsoleText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)

                    Color.clear
                        .frame(height: 1)
                        .id("console-bottom")
                }
                .background(Color(nsColor: .textBackgroundColor))
                .onChange(of: library.gameConsoleText) {
                    proxy.scrollTo("console-bottom", anchor: .bottom)
                }
            }
        }
        .background(.bar)
    }

    private var consoleText: String {
        library.gameConsoleText.isEmpty
            ? strings.gameConsolePlaceholder
            : library.gameConsoleText
    }

    private var attributedConsoleText: AttributedString {
        if library.gameConsoleText.isEmpty {
            var placeholder = AttributedString(consoleText)
            placeholder.foregroundColor = .secondary
            return placeholder
        }

        var output = AttributedString()
        let lines = consoleText.components(separatedBy: "\n")
        for index in lines.indices {
            var line = AttributedString(lines[index])
            line.foregroundColor = consoleColor(for: lines[index])
            output.append(line)

            if index != lines.indices.last {
                output.append(AttributedString("\n"))
            }
        }

        return output
    }

    private func consoleColor(for line: String) -> Color {
        let normalized = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalized.isEmpty {
            return .secondary
        }

        if normalized.hasPrefix("$ ") {
            return .cyan
        }

        if normalized.contains("error")
            || normalized.contains("failed")
            || normalized.contains("exception")
            || normalized.contains("crash")
            || normalized.contains("fatal")
            || normalized.contains("错误")
            || normalized.contains("失败") {
            return .red
        }

        if normalized.contains("warn")
            || normalized.contains("skipped")
            || normalized.contains("警告")
            || normalized.contains("跳过")
            || normalized.contains("正在停止") {
            return .orange
        }

        if normalized.contains("loaded")
            || normalized.contains("success")
            || normalized.contains("ready")
            || normalized.contains("saved")
            || normalized.contains("完成")
            || normalized.contains("成功")
            || normalized.contains("退出码：0") {
            return .green
        }

        if normalized.contains("debug") || normalized.contains("trace") {
            return .secondary
        }

        if normalized.contains("进程已退出") {
            return .secondary
        }

        return .primary
    }
}

private struct SidebarView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            Divider()

            List(selection: $library.selectedModID) {
                ForEach(library.filteredMods) { mod in
                    ModRowView(mod: mod, updateStatus: library.updateStatus(for: mod))
                        .tag(mod.id)
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $library.searchText, placement: .sidebar, prompt: strings.searchModsPrompt)

            if !library.scanErrors.isEmpty {
                Divider()
                ScanErrorStrip(count: library.scanErrors.count)
            }
        }
        .frame(minWidth: 360)
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stardew Mod Manager")
                        .font(.title3.weight(.semibold))
                    Text(library.rootURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                if library.isScanning
                    || library.isInstalling
                    || library.isChangingModState
                    || library.isGameRunning
                    || library.isCheckingUpdates {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            HStack(spacing: 8) {
                ForEach(ModListFilter.allCases) { filter in
                    Button {
                        library.selectedFilter = filter
                    } label: {
                        SummaryPill(
                            title: strings.filterLabel(filter),
                            value: library.count(for: filter),
                            tint: filterTint(for: filter),
                            isSelected: library.selectedFilter == filter
                        )
                    }
                    .buttonStyle(.plain)
                    .help(strings.filterHelp(filter))
                }
            }
        }
        .padding(16)
    }

    private func filterTint(for filter: ModListFilter) -> Color {
        switch filter {
        case .all:
            .accentColor
        case .enabled:
            .green
        case .attention:
            .orange
        case .updates:
            .blue
        case .disabled:
            .secondary
        }
    }
}

private struct SummaryPill: View {
    let title: String
    let value: Int
    let tint: Color
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(isSelected ? tint : .secondary)
            Text(value, format: .number)
                .font(.headline.monospacedDigit())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            isSelected ? tint.opacity(0.14) : Color(nsColor: .quaternaryLabelColor).opacity(0.16),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? tint.opacity(0.55) : .clear, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct ModRowView: View {
    @EnvironmentObject private var settings: AppSettings

    let mod: ModItem
    let updateStatus: ModUpdateStatus

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(iconTint, .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(mod.manifest.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(mod.manifest.version)
                    Text(strings.modKindLabel(mod.manifest.kind))
                    Text(strings.categoryName(mod.category))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            UpdateStatusBadge(status: updateStatus, compact: true)

            Text(strings.modStatusLabel(mod.status))
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusTint)
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch mod.manifest.kind {
        case .codeMod:
            "shippingbox"
        case .contentPack:
            "paintpalette"
        }
    }

    private var iconTint: Color {
        mod.manifest.kind == .codeMod ? .blue : .pink
    }

    private var statusTint: Color {
        switch mod.status {
        case .enabled:
            .green
        case .disabled:
            .secondary
        case .needsAttention:
            .orange
        }
    }
}

struct UpdateStatusBadge: View {
    @EnvironmentObject private var settings: AppSettings

    let status: ModUpdateStatus
    var compact = false

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        switch status {
        case .checking:
            ProgressView()
                .controlSize(.small)
        case .updateAvailable(let version, _):
            Text(compact ? strings.updateCompact : strings.updateAvailable(version: version))
                .font(.caption.weight(.semibold))
                .padding(.vertical, 3)
                .padding(.horizontal, 7)
                .foregroundStyle(.blue)
                .background(.blue.opacity(0.12), in: Capsule())
        case .failed:
            if !compact {
                Text(strings.updateStatusShortLabel(status))
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 7)
                    .foregroundStyle(.secondary)
                    .background(.quaternary, in: Capsule())
            }
        case .notChecked, .current:
            EmptyView()
        }
    }
}

private struct ScanErrorStrip: View {
    @EnvironmentObject private var settings: AppSettings

    let count: Int

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text(strings.scanErrorCount(count))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(12)
    }
}

private struct EmptyStateView: View {
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text(strings.noMods)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
