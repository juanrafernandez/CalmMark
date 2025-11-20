//
//  AppSettings.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftUI

enum ViewMode: String, Codable, CaseIterable {
    case editor = "Editor"
    case preview = "Preview"
    case split = "Split"
}

enum AppearanceMode: String, Codable, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Appearance Settings
    @AppStorage("appearanceMode") var appearanceMode: AppearanceMode = .system
    @AppStorage("editorFontSize") var editorFontSize: Double = 14.0
    @AppStorage("previewFontSize") var previewFontSize: Double = 16.0
    @AppStorage("maxPreviewWidth") var maxPreviewWidth: Double = 800.0

    // MARK: - Editor Settings
    @AppStorage("showLineNumbers") var showLineNumbers: Bool = true
    @AppStorage("syntaxHighlighting") var syntaxHighlighting: Bool = true
    @AppStorage("autoPairs") var autoPairs: Bool = true
    @AppStorage("wrapText") var wrapText: Bool = true

    // MARK: - Markdown Settings
    @AppStorage("enableTables") var enableTables: Bool = true
    @AppStorage("enableTaskLists") var enableTaskLists: Bool = true

    // MARK: - Default View Mode
    @AppStorage("defaultViewMode") var defaultViewMode: ViewMode = .split

    private init() {}

    func resetToDefaults() {
        appearanceMode = .system
        editorFontSize = 14.0
        previewFontSize = 16.0
        maxPreviewWidth = 800.0
        showLineNumbers = true
        syntaxHighlighting = true
        autoPairs = true
        wrapText = true
        enableTables = true
        enableTaskLists = true
        defaultViewMode = .split
    }
}
