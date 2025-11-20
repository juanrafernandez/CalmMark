//
//  FileItem.swift
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
            LogManager.shared.log(.error, "Error cargando contenido de \(url.path): \(error)", context: "FileItem")
        }
    }
}
