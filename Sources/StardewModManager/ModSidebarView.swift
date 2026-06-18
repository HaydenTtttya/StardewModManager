import StardewModCore
import SwiftUI

struct ModSidebarView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        VStack(spacing: 0) {
            LibraryHeaderView()

            Divider()

            List(selection: $library.selectedModID) {
                ForEach(library.filteredMods) { mod in
                    ModRowView(mod: mod, updateStatus: library.updateStatus(for: mod))
                        .tag(mod.id)
                        .contextMenu {
                            Button(mod.isDisabled ? strings.enableMod : strings.disableMod) {
                                library.setMod(mod, enabled: mod.isDisabled, language: settings.language)
                            }
                            Divider()
                            Button(strings.revealInFinder) {
                                library.revealModInFinder(mod)
                            }
                        }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $library.searchText, placement: .sidebar, prompt: strings.searchModsPrompt)

            if !library.scanErrors.isEmpty {
                Divider()
                ScanErrorStrip(count: library.scanErrors.count)
            }
        }
        .frame(minWidth: 320, idealWidth: 350, maxWidth: 420)
    }
}

private struct LibraryHeaderView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    private var isBusy: Bool {
        library.isScanning
            || library.isInstalling
            || library.isChangingModState
            || library.isCheckingUpdates
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .frame(width: 34, height: 34)
                    .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 2) {
                    Text(strings.modLibrary)
                        .font(.headline)
                    Text(strings.modCount(library.mods.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Button {
                library.chooseModsFolder(language: settings.language)
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "externaldrive")
                        .foregroundStyle(.secondary)
                    Text(library.rootURL.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .help(strings.chooseModsFolderHelp)

            HStack(spacing: 6) {
                ForEach(ModListFilter.allCases) { filter in
                    Button {
                        library.selectedFilter = filter
                    } label: {
                        SummaryPill(
                            title: strings.filterLabel(filter),
                            value: library.count(for: filter),
                            tint: tint(for: filter),
                            isSelected: library.selectedFilter == filter
                        )
                    }
                    .buttonStyle(.plain)
                    .help(strings.filterHelp(filter))
                }
            }
        }
        .padding(14)
    }

    private func tint(for filter: ModListFilter) -> Color {
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
        VStack(alignment: .leading, spacing: 1) {
            Text(value, format: .number)
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(isSelected ? tint : .primary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(isSelected ? tint : .secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? tint.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(isSelected ? tint.opacity(0.45) : Color.secondary.opacity(0.12), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 7))
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
            Image(systemName: mod.manifest.kind == .codeMod ? "shippingbox.fill" : "paintpalette.fill")
                .foregroundStyle(mod.manifest.kind == .codeMod ? .blue : .pink)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(mod.manifest.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text(mod.manifest.version)
                    Text("•")
                    Text(strings.modKindLabel(mod.manifest.kind))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 6)

            UpdateStatusBadge(status: updateStatus, compact: true)

            Circle()
                .fill(statusTint)
                .frame(width: 7, height: 7)
                .help(strings.modStatusLabel(mod.status))
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mod.manifest.name), \(strings.modStatusLabel(mod.status))")
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

private struct ScanErrorStrip: View {
    @EnvironmentObject private var settings: AppSettings

    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(settings.strings.scanErrorCount(count))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(12)
    }
}
