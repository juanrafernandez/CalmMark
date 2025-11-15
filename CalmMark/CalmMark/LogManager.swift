//
//  LogManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//  Sistema de logging para debugging y diagnóstico
//

import Foundation
import SwiftUI

enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case success = "✅ SUCCESS"
}

struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let context: String

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }

    var displayText: String {
        "[\(formattedTime)] \(level.rawValue) [\(context)] \(message)"
    }
}

class LogManager: ObservableObject {
    static let shared = LogManager()

    @Published var logs: [LogEntry] = []
    @Published var hasErrors: Bool = false

    private let maxLogs = 500 // Limitar logs para no consumir memoria

    private init() {
        log(.info, "CalmMark iniciado", context: "App")
    }

    func log(_ level: LogLevel, _ message: String, context: String = "General") {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            context: context
        )

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.logs.append(entry)

            // Actualizar flag de errores
            if level == .error {
                self.hasErrors = true
            }

            // Limitar logs
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }

            // Imprimir en consola también
            print(entry.displayText)
        }
    }

    func clearLogs() {
        DispatchQueue.main.async { [weak self] in
            self?.logs.removeAll()
            self?.hasErrors = false
        }
    }

    func clearErrors() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logs.removeAll { $0.level == .error }
            self.hasErrors = self.logs.contains { $0.level == .error }
        }
    }
}
