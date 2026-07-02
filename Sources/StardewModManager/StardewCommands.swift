import SwiftUI

struct StardewCommands: Commands {
    @ObservedObject var library: ModLibraryViewModel
    @ObservedObject var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some Commands {
        CommandMenu(strings.modLibrary) {
            Button(strings.installMod) {
                library.chooseAndInstallMod(language: settings.language)
            }
            .keyboardShortcut("i", modifiers: .command)
            .disabled(library.isInstalling)

            Button(strings.installTranslation) {
                library.chooseAndInstallTranslation(language: settings.language)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
            .disabled(library.isInstalling)

            Divider()

            Button(strings.refresh) {
                library.refresh()
            }
            .keyboardShortcut("r", modifiers: .command)

            Button(strings.checkUpdates) {
                library.checkForModUpdates()
            }
            .keyboardShortcut("u", modifiers: [.command, .shift])
            .disabled(library.isCheckingUpdates || library.mods.isEmpty)

            Divider()

            Button(library.selectedMod?.isDisabled == true ? strings.enableMod : strings.disableMod) {
                library.toggleSelectedModEnabled(language: settings.language)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(library.selectedMod == nil || library.isChangingModState)

            Button(strings.revealInFinder) {
                library.revealSelectedModInFinder()
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(library.selectedMod == nil)

            Divider()

            Button(strings.startGame) {
                library.launchGame(language: settings.language)
            }
            .keyboardShortcut(.return, modifiers: .command)
        }
    }
}
