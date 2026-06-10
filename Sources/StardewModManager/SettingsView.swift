import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    private var strings: AppStrings {
        settings.strings
    }

    var body: some View {
        Form {
            Section(strings.settingsGeneralSection) {
                Picker(strings.languageLabel, selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName(in: settings.language))
                            .tag(language)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(strings.languageHelp)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420)
        .navigationTitle(strings.settingsTitle)
    }
}
