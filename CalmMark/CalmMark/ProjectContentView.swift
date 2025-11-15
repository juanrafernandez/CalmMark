//
//  ProjectContentView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//  Main view for project/folder-based editing
//

import SwiftUI

struct ProjectContentView: View {
    @StateObject private var fileManager = FileSystemManager()
    @StateObject private var tabManager = TabManager()
    @StateObject private var settings = AppSettings.shared

    @State private var viewMode: ViewMode = AppSettings.shared.defaultViewMode
    @State private var showSidebar: Bool = true
    @State private var sidebarWidth: CGFloat = 250
    @State private var showPreviewPanel: Bool = true
    @State private var previewPanelWidth: CGFloat = 350
    @State private var showLogPanel: Bool = false
    @State private var logPanelHeight: CGFloat = 200
    @State private var showExportSheet = false
    @State private var exportType: ExportType = .html
    @State private var showCommandTemplates = false

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            ProjectToolbarView(
                viewMode: $viewMode,
                showSidebar: $showSidebar,
                showPreviewPanel: $showPreviewPanel,
                showLogPanel: $showLogPanel,
                fileManager: fileManager,
                tabManager: tabManager,
                onExportHTML: {
                    exportType = .html
                    showExportSheet = true
                },
                onExportPDF: {
                    exportType = .pdf
                    showExportSheet = true
                },
                onShowTemplates: {
                    showCommandTemplates = true
                }
            )

            Divider()

            // Tab bar (if files are open)
            if !tabManager.openFiles.isEmpty {
                TabBarView(tabManager: tabManager)
                Divider()
            }

            // Main content area with native NSSplitView for Xcode-level performance
            GeometryReader { geometry in
                VSplitView2(bottomHeight: $logPanelHeight) {
                    // Top: Horizontal split (Sidebar + Editor + Preview)
                    HSplitView3(
                        leadingWidth: $sidebarWidth,
                        trailingWidth: $previewPanelWidth
                    ) {
                        // Leading: Sidebar (optional)
                        Group {
                            if showSidebar {
                                FileNavigatorView(
                                    fileManager: fileManager,
                                    openFiles: $tabManager.openFiles,
                                    activeFile: $tabManager.activeFile
                                )
                            }
                        }
                    } center: {
                        // Center: Editor (always visible)
                        if let activeFile = tabManager.activeFile {
                            EditorView(text: Binding(
                                get: { activeFile.content },
                                set: { newValue in
                                    activeFile.content = newValue
                                    activeFile.isDirty = true
                                }
                            ), settings: settings)
                        } else {
                            WelcomeView(
                                fileManager: fileManager,
                                onOpenFolder: {
                                    fileManager.openFolder()
                                },
                                onCreateCommand: {
                                    showCommandTemplates = true
                                }
                            )
                        }
                    } trailing: {
                        // Trailing: Preview (optional)
                        Group {
                            if showPreviewPanel, let activeFile = tabManager.activeFile {
                                VStack(spacing: 0) {
                                    // Header del panel de preview
                                    HStack {
                                        Image(systemName: "doc.richtext")
                                            .font(.system(size: 12))
                                        Text("Preview")
                                            .font(.system(size: 12, weight: .semibold))

                                        Text("(\(activeFile.content.count) chars)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)

                                        Spacer()
                                        Button(action: {
                                            withAnimation {
                                                showPreviewPanel = false
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(NSColor.controlBackgroundColor))

                                    Divider()

                                    PreviewView(markdown: activeFile.content, settings: settings)
                                        .onAppear {
                                            LogManager.shared.log(.info, "Panel de Preview apareció para archivo: \(activeFile.name) con \(activeFile.content.count) caracteres", context: "ProjectContent")
                                        }
                                }
                            }
                        }
                    }
                } bottom: {
                    // Bottom: Log panel (optional)
                    Group {
                        if showLogPanel {
                            LogPanelView()
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .changeViewMode)) { notification in
            if let mode = notification.object as? ViewMode {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = mode
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportHTML)) { _ in
            exportType = .html
            showExportSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportPDF)) { _ in
            exportType = .pdf
            showExportSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showSidebar.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .togglePreviewPanel)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showPreviewPanel.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleLogPanel)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showLogPanel.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFolder)) { _ in
            fileManager.openFolder()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveActiveFile)) { _ in
            tabManager.saveActiveFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveAllFiles)) { _ in
            tabManager.saveAllFiles()
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeActiveTab)) { _ in
            if let active = tabManager.activeFile {
                tabManager.closeFile(active)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeAllTabs)) { _ in
            tabManager.closeAllFiles()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDroppedFile)) { notification in
            if let url = notification.object as? URL {
                tabManager.openFile(url: url)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let activeFile = tabManager.activeFile {
                ExportView(
                    markdown: activeFile.content,
                    exportType: exportType,
                    settings: settings,
                    isPresented: $showExportSheet
                )
            }
        }
        .sheet(isPresented: $showCommandTemplates) {
            CommandTemplatesView(
                fileManager: fileManager,
                isPresented: $showCommandTemplates
            )
        }
        .onAppear {
            // Load last opened folder if any
            if let lastFolderPath = UserDefaults.standard.string(forKey: "lastOpenedFolder"),
               FileManager.default.fileExists(atPath: lastFolderPath) {
                let url = URL(fileURLWithPath: lastFolderPath)
                fileManager.setRootFolder(url)
            }
        }
        .onChange(of: fileManager.rootFolder) { oldFolder, newFolder in
            // Save last opened folder
            if let folder = newFolder {
                UserDefaults.standard.set(folder.url.path, forKey: "lastOpenedFolder")
            }
        }
    }

}

// MARK: - Project Toolbar

struct ProjectToolbarView: View {
    @Binding var viewMode: ViewMode
    @Binding var showSidebar: Bool
    @Binding var showPreviewPanel: Bool
    @Binding var showLogPanel: Bool
    let fileManager: FileSystemManager
    let tabManager: TabManager
    var onExportHTML: () -> Void
    var onExportPDF: () -> Void
    var onShowTemplates: () -> Void
    @ObservedObject var logManager = LogManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Sidebar toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSidebar.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14))
                    .foregroundColor(showSidebar ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Sidebar (⌘0)")
            .padding(.leading, 12)

            // Preview panel toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPreviewPanel.toggle()
                }
            }) {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 14))
                    .foregroundColor(showPreviewPanel ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Preview Panel (⌥⌘9)")

            // Log panel toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showLogPanel.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 14))
                        .foregroundColor(showLogPanel ? .accentColor : .secondary)
                    if logManager.hasErrors {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Toggle Log Panel (⇧⌘L)")

            Divider()
                .frame(height: 16)

            // View mode selector (removed - now using panels)
            Text("Editor Mode")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()

            // Active file name
            if let activeFile = tabManager.activeFile {
                Text(activeFile.name)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Command templates button
            if fileManager.rootFolder != nil {
                Button(action: onShowTemplates) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("AI Command Templates")
            }

            // Export menu
            Menu {
                Button(action: onExportHTML) {
                    Label("Export as HTML", systemImage: "doc.text")
                }

                Button(action: onExportPDF) {
                    Label("Export as PDF", systemImage: "doc.richtext")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
            }
            .menuStyle(.borderlessButton)
            .help("Export")
            .padding(.trailing, 12)
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func iconForMode(_ mode: ViewMode) -> String {
        switch mode {
        case .editor:
            return "doc.text"
        case .preview:
            return "doc.richtext"
        case .split:
            return "rectangle.split.2x1"
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    let fileManager: FileSystemManager
    let onOpenFolder: () -> Void
    let onCreateCommand: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // Logo/Icon
            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("Welcome to CalmMark")
                    .font(.system(size: 32, weight: .semibold))

                Text("A minimalist Markdown editor for macOS")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                // Open Folder button
                Button(action: onOpenFolder) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Open Folder")
                    }
                    .frame(width: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // Or divider
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Quick actions
                HStack(spacing: 12) {
                    Button(action: {
                        openSampleFile()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 24))
                            Text("Open File")
                                .font(.caption)
                        }
                        .frame(width: 100, height: 80)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onCreateCommand) {
                        VStack(spacing: 8) {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 24))
                            Text("AI Commands")
                                .font(.caption)
                        }
                        .frame(width: 100, height: 80)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips:")
                    .font(.caption)
                    .fontWeight(.semibold)

                tipRow(icon: "command", text: "Press ⌘0 to toggle sidebar")
                tipRow(icon: "1.square", text: "Press ⌘1/2/3 to switch views")
                tipRow(icon: "folder", text: "Open a folder to work with projects")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .frame(width: 16)
            Text(text)
        }
    }

    private func openSampleFile() {
        let panel = NSOpenPanel()
        panel.title = "Open Markdown File"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Open just the file's parent directory
                fileManager.setRootFolder(url.deletingLastPathComponent())
            }
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let toggleSidebar = Notification.Name("toggleSidebar")
}
