import Foundation
import Testing
@testable import StardewModCore

@Test
func decodesSMAPIManifestKeys() throws {
    let json = """
    {
      "Name": "Content Patcher",
      "Author": "Pathoschild",
      "Version": "2.7.0",
      "Description": "Loads content packs.",
      "UniqueID": "Pathoschild.ContentPatcher",
      "EntryDll": "ContentPatcher.dll",
      "UpdateKeys": ["Nexus:1915"]
    }
    """.data(using: .utf8)!

    let manifest = try ManifestJSONDecoder.decode(ModManifest.self, from: json)

    #expect(manifest.name == "Content Patcher")
    #expect(manifest.uniqueID == "Pathoschild.ContentPatcher")
    #expect(manifest.kind == .codeMod)
    #expect(manifest.updateKeys == ["Nexus:1915"])
    #expect(manifest.nexusModID == 1915)
}

@Test
func decodesManifestWithJSONCCommentsAndUniqueIdAlias() throws {
    let json = #"""
    {
      /*
       | SMAPI bundled mods can use UniqueId.
       */
      "Name": "Console Commands",
      "Author": "SMAPI",
      "Version": "4.5.2",
      "UniqueId": "SMAPI.ConsoleCommands",
      "MinimumApiVersion": "4.5.2", // CRLF comments should not swallow the rest of the file.
      "Dependencies": [
        {
          "UniqueID": "Example.Optional",
          "IsRequired": false,
        },
      ],
    }
    """#
    .replacingOccurrences(of: "\n", with: "\r\n")
    .data(using: .utf8)!

    let manifest = try ManifestJSONDecoder.decode(ModManifest.self, from: json)

    #expect(manifest.uniqueID == "SMAPI.ConsoleCommands")
    #expect(manifest.dependencies?.first?.uniqueID == "Example.Optional")
}

@Test
func scanUsesNexusPlaceholderInsteadOfFolderCategory() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let modFolder = root
        .appendingPathComponent("My Local Folder", isDirectory: true)
        .appendingPathComponent("ExampleMod", isDirectory: true)
    try FileManager.default.createDirectory(at: modFolder, withIntermediateDirectories: true)

    let manifest = """
    {
      "Name": "Example Mod",
      "Author": "Example",
      "Version": "1.0.0",
      "UniqueID": "Example.Mod",
      "UpdateKeys": ["Nexus:1234"]
    }
    """
    try manifest.write(
        to: modFolder.appendingPathComponent("manifest.json"),
        atomically: true,
        encoding: .utf8
    )

    let result = ModScanner.scan(rootURL: root)

    #expect(result.mods.first?.category == "读取 Nexus 分类中")
}

@Test
func scanReportsMissingRequiredDependencies() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let modFolder = root.appendingPathComponent("ExampleMod", isDirectory: true)
    try FileManager.default.createDirectory(at: modFolder, withIntermediateDirectories: true)

    let manifest = """
    {
      "Name": "Example Mod",
      "Author": "Example",
      "Version": "1.0.0",
      "UniqueID": "Example.Mod",
      "Dependencies": [
        { "UniqueID": "Missing.Required", "IsRequired": true },
        { "UniqueID": "Missing.Optional", "IsRequired": false }
      ]
    }
    """
    try manifest.write(
        to: modFolder.appendingPathComponent("manifest.json"),
        atomically: true,
        encoding: .utf8
    )

    let result = ModScanner.scan(rootURL: root)

    #expect(result.mods.count == 1)
    #expect(result.mods[0].missingRequiredDependencies == ["Missing.Required"])
    #expect(result.mods[0].missingOptionalDependencies == ["Missing.Optional"])
    #expect(result.mods[0].status == .needsAttention)
}

@Test
func scanMarksDisabledFolders() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let modFolder = root.appendingPathComponent(".DisabledMod", isDirectory: true)
    try FileManager.default.createDirectory(at: modFolder, withIntermediateDirectories: true)

    let manifest = """
    {
      "Name": "Disabled Mod",
      "Author": "Example",
      "Version": "1.0.0",
      "UniqueID": "Example.Disabled"
    }
    """
    try manifest.write(
        to: modFolder.appendingPathComponent("manifest.json"),
        atomically: true,
        encoding: .utf8
    )

    let result = ModScanner.scan(rootURL: root)

    #expect(result.mods.first?.isDisabled == true)
    #expect(result.mods.first?.status == .disabled)
}

@Test
func modStateControllerDisablesModByRenamingFolder() throws {
    let fileManager = FileManager.default
    let root = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? fileManager.removeItem(at: root) }

    let modFolder = root.appendingPathComponent("ExampleMod", isDirectory: true)
    try fileManager.createDirectory(at: modFolder, withIntermediateDirectories: true)
    try writeManifest(name: "Example Mod", version: "1.0.0", uniqueID: "Example.Mod", to: modFolder)

    let mod = try #require(ModScanner.scan(rootURL: root).mods.first)
    let result = try ModStateController.setEnabled(false, for: mod, fileManager: fileManager)
    let scanResult = ModScanner.scan(rootURL: root, fileManager: fileManager)

    #expect(result.destinationURL.lastPathComponent == "ExampleMod.disabled")
    #expect(!fileManager.fileExists(atPath: modFolder.path))
    #expect(fileManager.fileExists(atPath: result.destinationURL.path))
    #expect(scanResult.mods.first?.isDisabled == true)
    #expect(scanResult.mods.first?.status == .disabled)
}

@Test
func modStateControllerEnablesModByRenamingFolder() throws {
    let fileManager = FileManager.default
    let root = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? fileManager.removeItem(at: root) }

    let modFolder = root.appendingPathComponent("ExampleMod.disabled", isDirectory: true)
    try fileManager.createDirectory(at: modFolder, withIntermediateDirectories: true)
    try writeManifest(name: "Example Mod", version: "1.0.0", uniqueID: "Example.Mod", to: modFolder)

    let mod = try #require(ModScanner.scan(rootURL: root).mods.first)
    let result = try ModStateController.setEnabled(true, for: mod, fileManager: fileManager)
    let scanResult = ModScanner.scan(rootURL: root, fileManager: fileManager)

    #expect(result.destinationURL.lastPathComponent == "ExampleMod")
    #expect(!fileManager.fileExists(atPath: modFolder.path))
    #expect(fileManager.fileExists(atPath: result.destinationURL.path))
    #expect(scanResult.mods.first?.isDisabled == false)
    #expect(scanResult.mods.first?.status == .enabled)
}

@Test
func modStateControllerDoesNotEnableWholeDisabledParentFolder() throws {
    let fileManager = FileManager.default
    let root = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? fileManager.removeItem(at: root) }

    let groupFolder = root.appendingPathComponent(".Disabled Group", isDirectory: true)
    let modFolder = groupFolder.appendingPathComponent("ExampleMod", isDirectory: true)
    try fileManager.createDirectory(at: modFolder, withIntermediateDirectories: true)
    try writeManifest(name: "Example Mod", version: "1.0.0", uniqueID: "Example.Mod", to: modFolder)

    let mod = try #require(ModScanner.scan(rootURL: root).mods.first)

    do {
        _ = try ModStateController.setEnabled(true, for: mod, fileManager: fileManager)
        Issue.record("Expected enabling a mod disabled by a parent folder to fail.")
    } catch let error as ModStateChangeError {
        #expect(error == .disabledByParentDirectory(mod.folderURL.standardizedFileURL))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    #expect(fileManager.fileExists(atPath: modFolder.path))
}

@Test
func installReplacesExistingModTransactionally() throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let modsRoot = tempRoot.appendingPathComponent("Mods", isDirectory: true)
    let downloadRoot = tempRoot.appendingPathComponent("Downloads", isDirectory: true)
    defer { try? fileManager.removeItem(at: tempRoot) }

    let oldModFolder = modsRoot.appendingPathComponent("ExampleMod", isDirectory: true)
    let newModFolder = downloadRoot.appendingPathComponent("ExampleMod", isDirectory: true)
    try fileManager.createDirectory(at: oldModFolder, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: newModFolder, withIntermediateDirectories: true)

    try writeManifest(
        name: "Example Mod",
        version: "1.0.0",
        uniqueID: "Example.Mod",
        to: oldModFolder
    )
    try "old data".write(
        to: oldModFolder.appendingPathComponent("obsolete.txt"),
        atomically: true,
        encoding: .utf8
    )

    try writeManifest(
        name: "Example Mod",
        version: "2.0.0",
        uniqueID: "Example.Mod",
        to: newModFolder
    )

    let result = try ModInstaller.install(sourceURL: newModFolder, into: modsRoot)
    let scanResult = ModScanner.scan(rootURL: modsRoot)

    #expect(result.installedCount == 1)
    #expect(result.replacedCount == 1)
    #expect(fileManager.fileExists(atPath: oldModFolder.path))
    #expect(!fileManager.fileExists(atPath: oldModFolder.appendingPathComponent("obsolete.txt").path))
    #expect(scanResult.mods.count == 1)
    #expect(scanResult.mods.first?.manifest.version == "2.0.0")
    #expect(
        try fileManager.contentsOfDirectory(atPath: modsRoot.path)
            .allSatisfy { !$0.hasPrefix(".stardew-mod-manager-transaction-") }
    )
}

@Test
func installKeepsExistingModWhenIncomingPackageCannotBeStaged() throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let modsRoot = tempRoot.appendingPathComponent("Mods", isDirectory: true)
    let packageRoot = tempRoot.appendingPathComponent("Package", isDirectory: true)
    let oldModFolder = modsRoot.appendingPathComponent("ExampleMod", isDirectory: true)
    let incomingModFolder = packageRoot.appendingPathComponent("ExampleMod", isDirectory: true)
    let unreadableFile = incomingModFolder.appendingPathComponent("unreadable.bin")
    defer {
        try? fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: unreadableFile.path)
        try? fileManager.removeItem(at: tempRoot)
    }

    try fileManager.createDirectory(at: oldModFolder, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: incomingModFolder, withIntermediateDirectories: true)
    try writeManifest(name: "Example Mod", version: "1.0.0", uniqueID: "Example.Mod", to: oldModFolder)
    try "old data".write(
        to: oldModFolder.appendingPathComponent("keep.txt"),
        atomically: true,
        encoding: .utf8
    )
    try writeManifest(name: "Example Mod", version: "2.0.0", uniqueID: "Example.Mod", to: incomingModFolder)
    try Data([0x01]).write(to: unreadableFile)
    try fileManager.setAttributes([.posixPermissions: 0o000], ofItemAtPath: unreadableFile.path)

    #expect(throws: (any Error).self) {
        _ = try ModInstaller.install(sourceURL: packageRoot, into: modsRoot)
    }

    let scanResult = ModScanner.scan(rootURL: modsRoot)
    #expect(scanResult.mods.first?.manifest.version == "1.0.0")
    #expect(fileManager.fileExists(atPath: oldModFolder.appendingPathComponent("keep.txt").path))
}

@Test
func installCopiesMultipleModFoldersFromPackageFolder() throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let modsRoot = tempRoot.appendingPathComponent("Mods", isDirectory: true)
    let packageRoot = tempRoot.appendingPathComponent("Package", isDirectory: true)
    defer { try? fileManager.removeItem(at: tempRoot) }

    let firstModFolder = packageRoot.appendingPathComponent("FirstMod", isDirectory: true)
    let secondModFolder = packageRoot.appendingPathComponent("SecondMod", isDirectory: true)
    try fileManager.createDirectory(at: firstModFolder, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: secondModFolder, withIntermediateDirectories: true)
    try writeManifest(name: "First Mod", version: "1.0.0", uniqueID: "Example.First", to: firstModFolder)
    try writeManifest(name: "Second Mod", version: "1.0.0", uniqueID: "Example.Second", to: secondModFolder)

    let result = try ModInstaller.install(sourceURL: packageRoot, into: modsRoot)
    let scanResult = ModScanner.scan(rootURL: modsRoot)

    #expect(result.installedCount == 2)
    #expect(Set(scanResult.mods.map(\.manifest.uniqueID)) == ["Example.First", "Example.Second"])
}

@Test
func installRejectsCurrentModsFolderAsSource() throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let modsRoot = tempRoot.appendingPathComponent("Mods", isDirectory: true)
    let modFolder = modsRoot.appendingPathComponent("ExistingMod", isDirectory: true)
    defer { try? fileManager.removeItem(at: tempRoot) }

    try fileManager.createDirectory(at: modFolder, withIntermediateDirectories: true)
    try writeManifest(name: "Existing Mod", version: "1.0.0", uniqueID: "Example.Existing", to: modFolder)

    do {
        _ = try ModInstaller.install(sourceURL: modsRoot, into: modsRoot)
        Issue.record("Expected installing from the current Mods folder to fail.")
    } catch let error as ModInstallError {
        #expect(error == .sourceInsideModsFolder(modsRoot.standardizedFileURL))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    #expect(fileManager.fileExists(atPath: modFolder.path))
}

@Test
func installCopiesRootLevelZipUsingManifestName() throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let modsRoot = tempRoot.appendingPathComponent("Mods", isDirectory: true)
    let packageRoot = tempRoot.appendingPathComponent("Package", isDirectory: true)
    let archiveURL = tempRoot.appendingPathComponent("RootLevelMod.zip")
    defer { try? fileManager.removeItem(at: tempRoot) }

    try fileManager.createDirectory(at: packageRoot, withIntermediateDirectories: true)
    try writeManifest(name: "Root Level Mod", version: "1.0.0", uniqueID: "Example.RootLevel", to: packageRoot)
    try "payload".write(
        to: packageRoot.appendingPathComponent("content.json"),
        atomically: true,
        encoding: .utf8
    )
    try createZip(from: packageRoot, at: archiveURL)

    let result = try ModInstaller.install(sourceURL: archiveURL, into: modsRoot)
    let destinationURL = modsRoot.appendingPathComponent("Root Level Mod", isDirectory: true)
    let scanResult = ModScanner.scan(rootURL: modsRoot)

    #expect(result.installedCount == 1)
    #expect(result.installedMods.first?.destinationURL == destinationURL)
    #expect(fileManager.fileExists(atPath: destinationURL.appendingPathComponent("manifest.json").path))
    #expect(scanResult.mods.first?.manifest.uniqueID == "Example.RootLevel")
}

@Test
func installTranslationCopiesStructuredI18nFilesIntoMatchingMods() throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let modsRoot = tempRoot.appendingPathComponent("Mods", isDirectory: true)
    let installedGroup = modsRoot
        .appendingPathComponent("拓展模组", isDirectory: true)
        .appendingPathComponent("Stardew Valley Expanded", isDirectory: true)
    let codeMod = installedGroup.appendingPathComponent("Stardew Valley Expanded Code", isDirectory: true)
    let contentPack = installedGroup.appendingPathComponent("[CP] Stardew Valley Expanded", isDirectory: true)
    let translationRoot = tempRoot
        .appendingPathComponent("Downloads", isDirectory: true)
        .appendingPathComponent("Stardew Valley Expanded", isDirectory: true)
    defer { try? fileManager.removeItem(at: tempRoot) }

    try fileManager.createDirectory(at: codeMod, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: contentPack, withIntermediateDirectories: true)
    try writeManifest(name: "SVE Code", version: "1.0.0", uniqueID: "FlashShifter.SVECode", to: codeMod)
    try writeManifest(name: "SVE CP", version: "1.0.0", uniqueID: "FlashShifter.SVECP", to: contentPack)
    try fileManager.createDirectory(
        at: codeMod.appendingPathComponent("i18n", isDirectory: true),
        withIntermediateDirectories: true
    )
    try #"{"old":"code"}"#.write(
        to: codeMod.appendingPathComponent("i18n/zh.json"),
        atomically: true,
        encoding: .utf8
    )

    let sourceCodeI18n = translationRoot
        .appendingPathComponent("Stardew Valley Expanded Code", isDirectory: true)
        .appendingPathComponent("i18n", isDirectory: true)
    let sourceCPI18n = translationRoot
        .appendingPathComponent("[CP] Stardew Valley Expanded", isDirectory: true)
        .appendingPathComponent("i18n", isDirectory: true)
    try fileManager.createDirectory(at: sourceCodeI18n, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: sourceCPI18n, withIntermediateDirectories: true)
    try #"{"new":"code"}"#.write(
        to: sourceCodeI18n.appendingPathComponent("zh.json"),
        atomically: true,
        encoding: .utf8
    )
    try #"{"new":"cp"}"#.write(
        to: sourceCPI18n.appendingPathComponent("zh.json"),
        atomically: true,
        encoding: .utf8
    )

    let result = try ModInstaller.installTranslation(sourceURL: translationRoot, into: modsRoot)

    #expect(result.installedCount == 2)
    #expect(result.createdCount == 1)
    #expect(result.overwrittenCount == 1)
    #expect(
        try String(contentsOf: codeMod.appendingPathComponent("i18n/zh.json"), encoding: .utf8)
            == #"{"new":"code"}"#
    )
    #expect(
        try String(contentsOf: contentPack.appendingPathComponent("i18n/zh.json"), encoding: .utf8)
            == #"{"new":"cp"}"#
    )
}

@Test
func installTranslationOverwritesSameNamedFilesInsideSelectedMod() throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let modsRoot = tempRoot.appendingPathComponent("Mods", isDirectory: true)
    let targetMod = modsRoot.appendingPathComponent("[CP] Example", isDirectory: true)
    let otherMod = modsRoot.appendingPathComponent("[CP] Other", isDirectory: true)
    let translationRoot = tempRoot.appendingPathComponent("Translation", isDirectory: true)
    defer { try? fileManager.removeItem(at: tempRoot) }

    try fileManager.createDirectory(
        at: targetMod.appendingPathComponent("code/Other", isDirectory: true),
        withIntermediateDirectories: true
    )
    try fileManager.createDirectory(
        at: otherMod.appendingPathComponent("code/Other", isDirectory: true),
        withIntermediateDirectories: true
    )
    try writeManifest(name: "Target", version: "1.0.0", uniqueID: "Example.Target", to: targetMod)
    try writeManifest(name: "Other", version: "1.0.0", uniqueID: "Example.Other", to: otherMod)
    try "old target".write(
        to: targetMod.appendingPathComponent("code/Other/Strings.json"),
        atomically: true,
        encoding: .utf8
    )
    try "old other".write(
        to: otherMod.appendingPathComponent("code/Other/Strings.json"),
        atomically: true,
        encoding: .utf8
    )
    try fileManager.createDirectory(at: translationRoot, withIntermediateDirectories: true)
    try "new strings".write(
        to: translationRoot.appendingPathComponent("Strings.json"),
        atomically: true,
        encoding: .utf8
    )

    let result = try ModInstaller.installTranslation(
        sourceURL: translationRoot,
        into: modsRoot,
        targetModURL: targetMod
    )

    #expect(result.installedCount == 1)
    #expect(result.overwrittenCount == 1)
    #expect(
        try String(contentsOf: targetMod.appendingPathComponent("code/Other/Strings.json"), encoding: .utf8)
            == "new strings"
    )
    #expect(
        try String(contentsOf: otherMod.appendingPathComponent("code/Other/Strings.json"), encoding: .utf8)
            == "old other"
    )
    #expect(!fileManager.fileExists(atPath: targetMod.appendingPathComponent("Strings.json").path))
}

@Test
func installTranslationCopiesSingleLocaleFileIntoSelectedModI18n() throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let modsRoot = tempRoot.appendingPathComponent("Mods", isDirectory: true)
    let targetMod = modsRoot.appendingPathComponent("ExampleMod", isDirectory: true)
    let sourceFile = tempRoot.appendingPathComponent("zh.json")
    defer { try? fileManager.removeItem(at: tempRoot) }

    try fileManager.createDirectory(at: targetMod, withIntermediateDirectories: true)
    try writeManifest(name: "Example", version: "1.0.0", uniqueID: "Example.Mod", to: targetMod)
    try #"{"hello":"你好"}"#.write(to: sourceFile, atomically: true, encoding: .utf8)

    let result = try ModInstaller.installTranslation(
        sourceURL: sourceFile,
        into: modsRoot,
        targetModURL: targetMod
    )

    #expect(result.installedCount == 1)
    #expect(result.createdCount == 1)
    #expect(
        try String(contentsOf: targetMod.appendingPathComponent("i18n/zh.json"), encoding: .utf8)
            == #"{"hello":"你好"}"#
    )
}

private func writeManifest(
    name: String,
    version: String,
    uniqueID: String,
    to folderURL: URL
) throws {
    let manifest = """
    {
      "Name": "\(name)",
      "Author": "Example",
      "Version": "\(version)",
      "UniqueID": "\(uniqueID)"
    }
    """
    try manifest.write(
        to: folderURL.appendingPathComponent("manifest.json"),
        atomically: true,
        encoding: .utf8
    )
}

private func createZip(from folderURL: URL, at archiveURL: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    process.arguments = ["-r", archiveURL.path, "."]
    process.currentDirectoryURL = folderURL
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw ZipCreationError(status: process.terminationStatus)
    }
}

private struct ZipCreationError: Error {
    let status: Int32
}
