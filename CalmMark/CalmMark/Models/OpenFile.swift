//
//  OpenFile.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Open File Model

class OpenFile: Identifiable, ObservableObject, Equatable {
    let id = UUID()
    let url: URL
    @Published var content: String
    @Published var isDirty: Bool = false
    @Published var isNew: Bool
    var cancellables = Set<AnyCancellable>()

    var name: String {
        url.lastPathComponent
    }

    var displayName: String {
        isDirty ? "\(name) •" : name
    }

    init(url: URL, content: String, isNew: Bool = false) {
        self.url = url
        self.content = content
        self.isNew = isNew
    }

    static func == (lhs: OpenFile, rhs: OpenFile) -> Bool {
        lhs.id == rhs.id
    }

    func save() throws {
        LogManager.shared.log(.info, "Guardando archivo a disco: \(name)", context: "OpenFile")

        try content.write(to: url, atomically: true, encoding: .utf8)
        isDirty = false

        // Limpiar hot exit cache cuando se guarda
        HotExitManager.shared.clearCache(for: url)
        LogManager.shared.log(.success, "Archivo guardado exitosamente: \(name)", context: "OpenFile")
    }

    func reload() throws {
        content = try String(contentsOf: url, encoding: .utf8)
        isDirty = false

        // Limpiar hot exit cache cuando se recarga
        HotExitManager.shared.clearCache(for: url)
    }
}
