import SwiftUI

struct ModWorkspaceView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings
    @SceneStorage("gameConsoleExpanded") private var isConsoleExpanded = true

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

            GameConsoleView(isExpanded: $isConsoleExpanded)
                .frame(height: isConsoleExpanded ? 220 : 44)
        }
    }
}

private struct GameConsoleView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    @Binding var isExpanded: Bool

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "terminal.fill")
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
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(isExpanded ? strings.hideConsole : strings.showConsole)

                Spacer()

                if isExpanded {
                    Button(strings.clear) {
                        library.clearGameConsole()
                    }
                    .buttonStyle(.borderless)
                    .disabled(library.gameConsoleText.isEmpty)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(isExpanded ? strings.hideConsole : strings.showConsole)
            }
            .padding(.horizontal, 14)
            .frame(height: 43)

            if isExpanded {
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
        }
        .background(.bar)
    }

    private var consoleText: String {
        library.gameConsoleText.isEmpty ? strings.gameConsolePlaceholder : library.gameConsoleText
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
        if normalized.isEmpty || normalized.contains("debug") || normalized.contains("trace") {
            return .secondary
        }
        if normalized.hasPrefix("$ ") {
            return .cyan
        }
        if ["error", "failed", "exception", "crash", "fatal", "错误", "失败"].contains(where: normalized.contains) {
            return .red
        }
        if ["warn", "skipped", "警告", "跳过", "正在停止"].contains(where: normalized.contains) {
            return .orange
        }
        if ["loaded", "success", "ready", "saved", "完成", "成功", "退出码：0"].contains(where: normalized.contains) {
            return .green
        }
        if normalized.contains("进程已退出") {
            return .secondary
        }
        return .primary
    }
}

private struct EmptyStateView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text(settings.strings.noMods)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
