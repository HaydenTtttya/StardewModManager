import SwiftUI

struct SurfaceCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
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
