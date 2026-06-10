import SwiftUI

@main
struct StardewModManagerApp: App {
    @StateObject private var library = ModLibraryViewModel()
    @StateObject private var settings = AppSettings()

    init() {
        CommandLineMode.runIfRequested()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .environmentObject(settings)
                .environment(\.locale, settings.language.locale)
                .frame(minWidth: 1040, minHeight: 680)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environment(\.locale, settings.language.locale)
        }
    }
}
