import Foundation

@MainActor
final class TerminalGameLauncher {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func launch(executableURL: URL) throws {
        let commandURL = try writeLaunchCommand(for: executableURL)
        let process = Process()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-b", "com.apple.Terminal", commandURL.path]
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw TerminalLaunchError.openFailed(message: message)
        }
    }

    private func writeLaunchCommand(for executableURL: URL) throws -> URL {
        let applicationSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let launcherDirectoryURL = applicationSupportURL
            .appendingPathComponent("StardewModManager", isDirectory: true)
        let commandURL = launcherDirectoryURL
            .appendingPathComponent("Launch SMAPI.command", isDirectory: false)

        try fileManager.createDirectory(
            at: launcherDirectoryURL,
            withIntermediateDirectories: true
        )

        let workingDirectory = executableURL.deletingLastPathComponent().path
        let command = """
        #!/bin/zsh
        cd -- \(shellQuoted(workingDirectory))
        exec \(shellQuoted(executableURL.path))

        """
        try command.write(to: commandURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: commandURL.path
        )
        return commandURL
    }

    private func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

private enum TerminalLaunchError: LocalizedError {
    case openFailed(message: String)

    var errorDescription: String? {
        switch self {
        case let .openFailed(message):
            message.isEmpty ? "Terminal could not be opened." : message
        }
    }
}
