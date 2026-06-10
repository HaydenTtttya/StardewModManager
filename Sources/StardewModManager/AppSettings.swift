import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: Self {
        self
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    func displayName(in language: AppLanguage) -> String {
        switch (self, language) {
        case (.simplifiedChinese, .simplifiedChinese):
            "简体中文"
        case (.simplifiedChinese, .english):
            "Simplified Chinese"
        case (.english, .simplifiedChinese):
            "英语"
        case (.english, .english):
            "English"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    private static let languageDefaultsKey = "AppLanguage"

    private let defaults: UserDefaults

    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Self.languageDefaultsKey)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedLanguage = defaults.string(forKey: Self.languageDefaultsKey)
            .flatMap(AppLanguage.init(rawValue:))
        language = savedLanguage ?? .simplifiedChinese
    }

    var strings: AppStrings {
        AppStrings(language: language)
    }
}
