import Foundation

struct ModsFolderStore {
    private static let defaultsKey = "SelectedModsFolderPath"

    private let defaults: UserDefaults
    private let fileManager: FileManager

    init(defaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.defaults = defaults
        self.fileManager = fileManager
    }

    func load() -> URL? {
        guard let path = defaults.string(forKey: Self.defaultsKey), !path.isEmpty else {
            return nil
        }

        let url = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return nil
        }
        return url
    }

    func save(_ url: URL) {
        defaults.set(url.standardizedFileURL.path, forKey: Self.defaultsKey)
    }
}
