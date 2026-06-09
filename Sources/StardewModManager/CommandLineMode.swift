import Foundation
import StardewModCore

enum CommandLineMode {
    static func runIfRequested(arguments: [String] = CommandLine.arguments) {
        if arguments.contains("--help") || arguments.contains("-h") {
            print(
                """
                StardewModManager

                Usage:
                  swift run StardewModManager
                  swift run StardewModManager --scan [mods-folder]

                Options:
                  --scan    Print a manifest scan summary without opening the app window.
                  --help    Print this help text.
                """
            )
            Foundation.exit(0)
        }

        guard let scanIndex = arguments.firstIndex(of: "--scan") else {
            return
        }

        let path: String
        if arguments.indices.contains(scanIndex + 1), !arguments[scanIndex + 1].hasPrefix("-") {
            path = arguments[scanIndex + 1]
        } else {
            path = DefaultModsLocator.bestGuess().path
        }

        let result = ModScanner.scan(rootURL: URL(fileURLWithPath: path))
        let enabled = result.mods.filter { $0.status == .enabled }.count
        let disabled = result.mods.filter { $0.status == .disabled }.count
        let attention = result.mods.filter { $0.status == .needsAttention }.count

        print("Mods folder: \(result.rootURL.path)")
        print("Mods: \(result.mods.count)")
        print("Enabled: \(enabled)")
        print("Needs attention: \(attention)")
        print("Disabled: \(disabled)")
        print("Read errors: \(result.errors.count)")

        if !result.errors.isEmpty {
            print("")
            print("Errors:")
            for error in result.errors.prefix(10) {
                print("- \(error.fileURL.path): \(error.message)")
            }
        }

        Foundation.exit(result.errors.isEmpty ? 0 : 1)
    }
}
