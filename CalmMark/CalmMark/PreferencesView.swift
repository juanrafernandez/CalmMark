//
//  PreferencesView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct PreferencesView: View {
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        TabView {
            AppearancePreferences(settings: settings)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            EditorPreferences(settings: settings)
                .tabItem {
                    Label("Editor", systemImage: "doc.text")
                }

            MarkdownPreferences(settings: settings)
                .tabItem {
                    Label("Markdown", systemImage: "m.square")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct AppearancePreferences: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Theme")
                    .font(.headline)
            }

            Section {
                HStack {
                    Text("Editor Font Size")
                    Spacer()
                    Slider(value: $settings.editorFontSize, in: 10...24, step: 1)
                        .frame(width: 200)
                    Text("\(Int(settings.editorFontSize)) pt")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }

                HStack {
                    Text("Preview Font Size")
                    Spacer()
                    Slider(value: $settings.previewFontSize, in: 12...28, step: 1)
                        .frame(width: 200)
                    Text("\(Int(settings.previewFontSize)) pt")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }

                HStack {
                    Text("Preview Max Width")
                    Spacer()
                    Slider(value: $settings.maxPreviewWidth, in: 600...1200, step: 50)
                        .frame(width: 200)
                    Text("\(Int(settings.maxPreviewWidth)) px")
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }
            } header: {
                Text("Typography")
                    .font(.headline)
            }

            Spacer()

            Button("Reset to Defaults") {
                settings.resetToDefaults()
            }
        }
        .padding(20)
    }
}

struct EditorPreferences: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Show Line Numbers", isOn: $settings.showLineNumbers)
                Toggle("Syntax Highlighting", isOn: $settings.syntaxHighlighting)
                Toggle("Auto-pair Brackets", isOn: $settings.autoPairs)
                Toggle("Wrap Text", isOn: $settings.wrapText)
            } header: {
                Text("Editor Options")
                    .font(.headline)
            }

            Section {
                Picker("Default View Mode", selection: $settings.defaultViewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            } header: {
                Text("View")
                    .font(.headline)
            }

            Spacer()
        }
        .padding(20)
    }
}

struct MarkdownPreferences: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Enable Tables", isOn: $settings.enableTables)
                    .help("Support for GitHub-flavored markdown tables")

                Toggle("Enable Task Lists", isOn: $settings.enableTaskLists)
                    .help("Support for - [ ] and - [x] checkboxes")
            } header: {
                Text("Extensions")
                    .font(.headline)
            }

            Section {
                Text("CalmMark supports standard Markdown syntax with optional extensions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Supported elements:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("• Headers (# to ######)")
                    Text("• Bold, Italic, Code")
                    Text("• Lists (ordered & unordered)")
                    Text("• Links and Images")
                    Text("• Blockquotes")
                    Text("• Code blocks")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            } header: {
                Text("Information")
                    .font(.headline)
            }

            Spacer()
        }
        .padding(20)
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
#endif
