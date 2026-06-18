import Foundation

@MainActor
final class GameProcessController {
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?

    var isRunning: Bool {
        process?.isRunning == true
    }

    var processIdentifier: Int32? {
        guard let process, process.isRunning else {
            return nil
        }
        return process.processIdentifier
    }

    func launch(
        executableURL: URL,
        onOutput: @escaping @MainActor @Sendable (String) -> Void,
        onTermination: @escaping @MainActor @Sendable (Int32) -> Void
    ) throws {
        reset()

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = executableURL
        process.currentDirectoryURL = executableURL.deletingLastPathComponent()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                return
            }
            let text = String(decoding: data, as: UTF8.self)
            Task { @MainActor in
                onOutput(text)
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                return
            }
            let text = String(decoding: data, as: UTF8.self)
            Task { @MainActor in
                onOutput(text)
            }
        }

        process.terminationHandler = { [weak self] process in
            let status = process.terminationStatus
            Task { @MainActor [weak self] in
                self?.reset()
                onTermination(status)
            }
        }

        self.process = process
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe

        do {
            try process.run()
        } catch {
            reset()
            throw error
        }
    }

    func stop() {
        guard let process, process.isRunning else {
            return
        }
        process.terminate()
    }

    func reset() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        errorPipe = nil
        process = nil
    }
}
