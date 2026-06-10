import StardewModCore
import SwiftUI

struct ModDetailView: View {
    @EnvironmentObject private var settings: AppSettings

    let mod: ModItem
    let updateStatus: ModUpdateStatus
    let isChangingState: Bool
    let onSetEnabled: (Bool) -> Void

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                titleBlock
                issueBlock
                updateStatusBlock
                metadataGrid
                dependencySection
                updateKeySection
                descriptionSection
            }
            .padding(28)
            .frame(maxWidth: 920, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: mod.manifest.kind == .codeMod ? "shippingbox" : "paintpalette")
                    .font(.system(size: 30))
                    .foregroundStyle(mod.manifest.kind == .codeMod ? .blue : .pink)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 6) {
                    Text(mod.manifest.name)
                        .font(.largeTitle.weight(.semibold))
                        .textSelection(.enabled)

                    HStack(spacing: 8) {
                        StatusBadge(status: mod.status)
                        UpdateStatusBadge(status: updateStatus)
                        Text(mod.manifest.version)
                            .font(.callout.weight(.medium))
                        Text(strings.authorName(mod.manifest.author))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 16)

                Toggle(
                    strings.enabledToggle,
                    isOn: Binding(
                        get: { !mod.isDisabled },
                        set: { isEnabled in
                            onSetEnabled(isEnabled)
                        }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.regular)
                .disabled(isChangingState)
                .help(mod.isDisabled ? strings.enableThisModHelp : strings.disableThisModHelp)
            }

            Text(mod.relativePath)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private var issueBlock: some View {
        if mod.hasIssues || mod.isDisabled {
            VStack(alignment: .leading, spacing: 10) {
                if mod.isDisabled {
                    IssueLine(icon: "pause.circle", tint: .secondary, text: strings.modDisabledIssue)
                }

                if mod.isDuplicateUniqueID {
                    IssueLine(icon: "doc.on.doc", tint: .orange, text: strings.duplicateUniqueIDIssue)
                }

                ForEach(mod.missingRequiredDependencies, id: \.self) { uniqueID in
                    IssueLine(icon: "exclamationmark.triangle", tint: .orange, text: strings.missingRequiredDependency(uniqueID))
                }
            }
            .padding(14)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private var updateStatusBlock: some View {
        switch updateStatus {
        case .checking:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(strings.checkingUpdates)
                    .foregroundStyle(.secondary)
            }
        case .updateAvailable(let version, let url):
            VStack(alignment: .leading, spacing: 10) {
                IssueLine(
                    icon: "arrow.down.circle",
                    tint: .blue,
                    text: strings.foundNewVersion(version: version, currentVersion: mod.manifest.version)
                )

                if let url {
                    Link(destination: url) {
                        Label(strings.openDownloadPage, systemImage: "safari")
                    }
                }
            }
            .padding(14)
            .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        case .failed(let message):
            IssueLine(icon: "exclamationmark.triangle", tint: .secondary, text: strings.updateCheckFailed(message))
                .padding(14)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        case .notChecked, .current:
            EmptyView()
        }
    }

    private var metadataGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
            MetadataRow(label: "UniqueID", value: mod.manifest.uniqueID)
            MetadataRow(label: strings.metadataType, value: strings.modKindLabel(mod.manifest.kind))
            MetadataRow(label: strings.metadataCategory, value: strings.categoryName(mod.category))
            MetadataRow(label: strings.metadataPath, value: mod.folderURL.path)

            if let entryDll = mod.manifest.entryDll {
                MetadataRow(label: "EntryDll", value: entryDll)
            }

            if let contentPackFor = mod.manifest.contentPackFor {
                MetadataRow(label: strings.metadataContentPackTarget, value: contentPackFor.uniqueID)
            }

            if let minimumApiVersion = mod.manifest.minimumApiVersion {
                MetadataRow(label: "SMAPI", value: minimumApiVersion)
            }

            if let minimumGameVersion = mod.manifest.minimumGameVersion {
                MetadataRow(label: strings.metadataGameVersion, value: minimumGameVersion)
            }
        }
        .font(.body)
    }

    @ViewBuilder
    private var dependencySection: some View {
        if let dependencies = mod.manifest.dependencies, !dependencies.isEmpty {
            DetailSection(title: strings.dependencies) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dependencies, id: \.uniqueID) { dependency in
                        HStack(spacing: 8) {
                            Image(systemName: dependency.required ? "link" : "link.badge.plus")
                                .foregroundStyle(dependency.required ? .primary : .secondary)
                            Text(dependency.uniqueID)
                                .textSelection(.enabled)
                            if let minimumVersion = dependency.minimumVersion {
                                Text(minimumVersion)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(dependency.required ? strings.required : strings.optional)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(dependency.required ? .orange : .secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var updateKeySection: some View {
        if let updateKeys = mod.manifest.updateKeys, !updateKeys.isEmpty {
            DetailSection(title: strings.updateSources) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(updateKeys, id: \.self) { updateKey in
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(.secondary)
                            Text(updateKey)
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let description = mod.manifest.description, !description.isEmpty {
            DetailSection(title: strings.description) {
                Text(description)
                    .textSelection(.enabled)
            }
        }
    }
}

private struct StatusBadge: View {
    @EnvironmentObject private var settings: AppSettings

    let status: ModStatus

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        Text(strings.modStatusLabel(status))
            .font(.caption.weight(.semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: Capsule())
    }

    private var tint: Color {
        switch status {
        case .enabled:
            .green
        case .disabled:
            .secondary
        case .needsAttention:
            .orange
        }
    }
}

private struct IssueLine: View {
    let icon: String
    let tint: Color
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .foregroundStyle(.primary)
        }
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
        }
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content
        }
    }
}
