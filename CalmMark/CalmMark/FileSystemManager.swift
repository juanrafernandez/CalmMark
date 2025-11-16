//
//  FileSystemManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import AppKit

// MARK: - File Item Model

class FileItem: Identifiable, ObservableObject, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let isClaudeCommand: Bool
    @Published var isExpanded: Bool = false
    @Published var children: [FileItem] = []

    weak var parent: FileItem?

    init(url: URL, parent: FileItem? = nil) {
        self.url = url
        self.name = url.lastPathComponent
        self.parent = parent

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue

        // Detect Claude command files
        self.isClaudeCommand = url.pathComponents.contains(".claude") &&
                               url.pathComponents.contains("commands") &&
                               url.pathExtension == "md"
    }

    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }

    var isMarkdown: Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "md" || ext == "markdown"
    }

    var icon: String {
        if isClaudeCommand {
            return "terminal.fill"
        } else if isDirectory {
            return isExpanded ? "folder.fill" : "folder"
        } else if isMarkdown {
            return "doc.text"
        } else {
            return "doc"
        }
    }

    var iconColor: NSColor {
        if isClaudeCommand {
            return .systemPurple
        } else if isDirectory {
            return .systemBlue
        } else if isMarkdown {
            return .systemTeal
        } else {
            return .secondaryLabelColor
        }
    }

    func loadChildren() {
        guard isDirectory else { return }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            // Sort: directories first, then alphabetically
            let sorted = contents.sorted { item1, item2 in
                var isDir1: ObjCBool = false
                var isDir2: ObjCBool = false
                FileManager.default.fileExists(atPath: item1.path, isDirectory: &isDir1)
                FileManager.default.fileExists(atPath: item2.path, isDirectory: &isDir2)

                if isDir1.boolValue != isDir2.boolValue {
                    return isDir1.boolValue
                }
                return item1.lastPathComponent.lowercased() < item2.lastPathComponent.lowercased()
            }

            children = sorted.map { FileItem(url: $0, parent: self) }
        } catch {
            print("Error loading children for \(url.path): \(error)")
        }
    }
}

// MARK: - File System Manager

class FileSystemManager: ObservableObject {
    @Published var rootFolder: FileItem?
    @Published var selectedFile: FileItem?

    // Open folder
    func openFolder() {
        let panel = NSOpenPanel()
        panel.title = "Open Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.setRootFolder(url)
        }
    }

    func setRootFolder(_ url: URL) {
        let root = FileItem(url: url)
        root.isExpanded = true
        root.loadChildren()
        rootFolder = root

        // Guardar bookmark con permisos persistentes
        saveBookmark(for: url)
    }

    // MARK: - Bookmark Persistence

    private func saveBookmark(for url: URL) {
        do {
            // Crear security-scoped bookmark
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            // Guardar en UserDefaults
            UserDefaults.standard.set(bookmarkData, forKey: "lastOpenedFolderBookmark")
            UserDefaults.standard.set(url.path, forKey: "lastOpenedFolder")
            print("📌 [FileSystemManager] Bookmark saved for: \(url.path)")
        } catch {
            print("❌ [FileSystemManager] Error creating bookmark: \(error)")
        }
    }

    func restoreLastFolder() -> Bool {
        // Intentar restaurar desde bookmark
        guard let bookmarkData = UserDefaults.standard.data(forKey: "lastOpenedFolderBookmark") else {
            print("⚠️ [FileSystemManager] No bookmark found")
            return false
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            // Iniciar acceso con security scope
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ [FileSystemManager] Failed to access security-scoped resource")
                return false
            }

            // Cargar la carpeta
            setRootFolder(url)

            // Si el bookmark está obsoleto, recrearlo
            if isStale {
                print("⚠️ [FileSystemManager] Bookmark is stale, recreating...")
                saveBookmark(for: url)
            }

            print("✅ [FileSystemManager] Restored folder from bookmark: \(url.path)")
            return true
        } catch {
            print("❌ [FileSystemManager] Error restoring bookmark: \(error)")
            return false
        }
    }

    // Get all markdown files in project
    func getAllMarkdownFiles() -> [FileItem] {
        guard let root = rootFolder else { return [] }
        var markdownFiles: [FileItem] = []

        func traverse(_ item: FileItem) {
            if item.isMarkdown {
                markdownFiles.append(item)
            }
            if item.isDirectory {
                item.loadChildren()
                for child in item.children {
                    traverse(child)
                }
            }
        }

        traverse(root)
        return markdownFiles
    }

    // Get Claude command files
    func getClaudeCommandFiles() -> [FileItem] {
        getAllMarkdownFiles().filter { $0.isClaudeCommand }
    }

    // Create new file
    func createNewFile(in folder: FileItem, name: String, content: String = "") -> Bool {
        guard folder.isDirectory else { return false }

        let newFileURL = folder.url.appendingPathComponent(name)

        do {
            try content.write(to: newFileURL, atomically: true, encoding: .utf8)
            folder.loadChildren()
            return true
        } catch {
            print("Error creating file: \(error)")
            return false
        }
    }

    // Create new folder
    func createNewFolder(in folder: FileItem, name: String) -> Bool {
        guard folder.isDirectory else { return false }

        let newFolderURL = folder.url.appendingPathComponent(name)

        do {
            try FileManager.default.createDirectory(
                at: newFolderURL,
                withIntermediateDirectories: false
            )
            folder.loadChildren()
            return true
        } catch {
            print("Error creating folder: \(error)")
            return false
        }
    }

    // Reveal in Finder
    func revealInFinder(_ item: FileItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
}
