import SwiftUI

@main
struct StardewModManagerApp: App {
    @StateObject private var library = ModLibraryViewModel()

    init() {
        CommandLineMode.runIfRequested()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .frame(minWidth: 1040, minHeight: 680)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
