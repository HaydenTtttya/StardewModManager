import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var library: ModLibraryViewModel
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        NavigationSplitView {
            ModSidebarView()
        } detail: {
            ModWorkspaceView()
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            MainToolbarContent()
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
