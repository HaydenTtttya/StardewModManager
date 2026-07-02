import SwiftUI

struct ModWorkspaceView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
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
