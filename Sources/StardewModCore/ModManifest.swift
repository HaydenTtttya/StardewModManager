import Foundation

public struct ModManifest: Decodable, Equatable, Sendable {
    public let name: String
    public let author: String?
    public let version: String
    public let description: String?
    public let uniqueID: String
    public let entryDll: String?
    public let contentPackFor: ContentPackFor?
    public let minimumApiVersion: String?
    public let minimumGameVersion: String?
    public let dependencies: [ModDependency]?
    public let updateKeys: [String]?

    public var displayAuthor: String {
        author?.isEmpty == false ? author! : "未知作者"
    }

    public var kind: ModKind {
        contentPackFor == nil ? .codeMod : .contentPack
    }

    public var nexusModID: Int? {
        updateKeys?.compactMap(Self.nexusModID(from:)).first
    }

    public init(
        name: String,
        author: String?,
        version: String,
        description: String?,
        uniqueID: String,
        entryDll: String?,
        contentPackFor: ContentPackFor?,
        minimumApiVersion: String?,
        minimumGameVersion: String?,
        dependencies: [ModDependency]?,
        updateKeys: [String]?
    ) {
        self.name = name
        self.author = author
        self.version = version
        self.description = description
        self.uniqueID = uniqueID
        self.entryDll = entryDll
        self.contentPackFor = contentPackFor
        self.minimumApiVersion = minimumApiVersion
        self.minimumGameVersion = minimumGameVersion
        self.dependencies = dependencies
        self.updateKeys = updateKeys
    }

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case author = "Author"
        case version = "Version"
        case description = "Description"
        case uniqueID = "UniqueID"
        case uniqueId = "UniqueId"
        case entryDll = "EntryDll"
        case contentPackFor = "ContentPackFor"
        case minimumApiVersion = "MinimumApiVersion"
        case minimumGameVersion = "MinimumGameVersion"
        case dependencies = "Dependencies"
        case updateKeys = "UpdateKeys"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uniqueID = try container.decodeIfPresent(String.self, forKey: .uniqueID)
            ?? container.decode(String.self, forKey: .uniqueId)

        self.init(
            name: try container.decode(String.self, forKey: .name),
            author: try container.decodeIfPresent(String.self, forKey: .author),
            version: try container.decode(String.self, forKey: .version),
            description: try container.decodeIfPresent(String.self, forKey: .description),
            uniqueID: uniqueID,
            entryDll: try container.decodeIfPresent(String.self, forKey: .entryDll),
            contentPackFor: try container.decodeIfPresent(ContentPackFor.self, forKey: .contentPackFor),
            minimumApiVersion: try container.decodeIfPresent(String.self, forKey: .minimumApiVersion),
            minimumGameVersion: try container.decodeIfPresent(String.self, forKey: .minimumGameVersion),
            dependencies: try container.decodeIfPresent([ModDependency].self, forKey: .dependencies),
            updateKeys: try container.decodeIfPresent([String].self, forKey: .updateKeys)
        )
    }

    private static func nexusModID(from updateKey: String) -> Int? {
        guard updateKey.localizedCaseInsensitiveContains("Nexus:") else {
            return nil
        }

        let parts = updateKey.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else {
            return nil
        }

        let digits = parts[1].prefix { $0.isNumber }
        return Int(digits)
    }
}

public struct ContentPackFor: Decodable, Equatable, Sendable {
    public let uniqueID: String
    public let minimumVersion: String?

    enum CodingKeys: String, CodingKey {
        case uniqueID = "UniqueID"
        case minimumVersion = "MinimumVersion"
    }
}

public struct ModDependency: Decodable, Equatable, Sendable {
    public let uniqueID: String
    public let minimumVersion: String?
    public let isRequired: Bool?

    public var required: Bool {
        isRequired ?? true
    }

    enum CodingKeys: String, CodingKey {
        case uniqueID = "UniqueID"
        case minimumVersion = "MinimumVersion"
        case isRequired = "IsRequired"
    }
}

public enum ModKind: String, Codable, Sendable {
    case codeMod
    case contentPack

    public var label: String {
        switch self {
        case .codeMod:
            "代码模组"
        case .contentPack:
            "内容包"
        }
    }
}
