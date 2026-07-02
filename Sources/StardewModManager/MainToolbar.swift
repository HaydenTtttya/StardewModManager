import SwiftUI

struct MainToolbarContent: ToolbarContent {
    var body: some ToolbarContent {
        if #available(macOS 26.0, *) {
            ToolbarItem(placement: .primaryAction) {
                GameLaunchToolbarButton()
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarSpacer(.fixed, placement: .primaryAction)

            ToolbarItemGroup(placement: .primaryAction) {
                PrimaryToolbarActions()
            }
        } else {
            ToolbarItem(placement: .primaryAction) {
                GameLaunchToolbarButton()
            }

            ToolbarItemGroup(placement: .primaryAction) {
                PrimaryToolbarActions()
            }
        }
    }
}

private struct GameLaunchToolbarButton: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.extraLarge)
                .tint(.red)
                .labelStyle(.iconOnly)
        } else {
            button
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(.red)
                .labelStyle(.iconOnly)
        }
    }

    private var button: some View {
        Button {
            library.launchGame(language: settings.language)
        } label: {
            Label(strings.startGame, systemImage: "play.fill")
        }
        .disabled(library.isInstalling)
        .help(strings.startGameHelp)
    }
}

private struct PrimaryToolbarActions: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        Button {
            library.chooseAndInstallMod(language: settings.language)
        } label: {
            Label(strings.installMod, systemImage: "square.and.arrow.down")
        }
        .disabled(library.isInstalling)
        .help(strings.installModHelp)

        Button {
            library.refresh()
        } label: {
            Label(strings.refresh, systemImage: "arrow.clockwise")
        }
        .help(strings.refreshHelp)

        Menu {
            Button {
                library.chooseAndInstallTranslation(language: settings.language)
            } label: {
                Label(strings.installTranslation, systemImage: "globe.asia.australia")
            }
            .disabled(library.isInstalling)

            Divider()

            Button {
                library.chooseModsFolder(language: settings.language)
            } label: {
                Label(strings.chooseDirectory, systemImage: "folder")
            }

            Button {
                library.checkForModUpdates()
            } label: {
                Label(strings.checkUpdates, systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(library.isCheckingUpdates || library.mods.isEmpty)

            Divider()

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

            Button {
                library.revealSelectedModInFinder()
            } label: {
                Label(strings.revealInFinder, systemImage: "magnifyingglass")
            }
            .disabled(library.selectedMod == nil)
        } label: {
            Label(strings.moreActions, systemImage: "ellipsis.circle")
        }
        .help(strings.moreActions)
    }
}
