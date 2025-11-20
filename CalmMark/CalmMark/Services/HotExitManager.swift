//
//  HotExitManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation

// MARK: - Hot Exit Manager

class HotExitManager {
    static let shared = HotExitManager()
    private let userDefaults = UserDefaults.standard
    private let prefix = "hotExit_"

    private init() {}

    func saveUnsavedContent(for url: URL, content: String, isDirty: Bool) {
        guard isDirty else {
            // Si no está dirty, limpiar cualquier cache
            clearCache(for: url)
            return
        }

        let key = hotExitKey(for: url)
        userDefaults.set(content, forKey: key)
    }

    func loadUnsavedContent(for url: URL) -> String? {
        let key = hotExitKey(for: url)
        if let cachedContent = userDefaults.string(forKey: key) {
            LogManager.shared.log(.info, "Restaurado contenido sin guardar: \(url.lastPathComponent)", context: "HotExit")
            return cachedContent
        }
        return nil
    }

    func clearCache(for url: URL) {
        let key = hotExitKey(for: url)
        userDefaults.removeObject(forKey: key)
        LogManager.shared.log(.debug, "Cache limpiado: \(url.lastPathComponent)", context: "HotExit")
    }

    private func hotExitKey(for url: URL) -> String {
        return prefix + url.path
    }
}
