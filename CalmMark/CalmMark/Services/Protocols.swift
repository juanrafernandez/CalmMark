//
//  Protocols.swift
//  CalmMark
//
//  Created by Claude on 2025-11-20.
//  Service protocols for dependency injection and testability
//

import Foundation

// MARK: - Hot Exit Service Protocol

protocol HotExitService {
    func saveUnsavedContent(for url: URL, content: String, isDirty: Bool)
    func loadUnsavedContent(for url: URL) -> String?
    func clearCache(for url: URL)
}

// MARK: - Logging Service Protocol

protocol LoggingService {
    func log(_ level: LogLevel, _ message: String, context: String)
}

// MARK: - Template Service Protocol

protocol TemplateService {
    var templates: [CommandTemplate] { get }
    func getTemplatesByCategory(_ category: TemplateCategory) -> [CommandTemplate]
    func createCommandFile(from template: CommandTemplate, in directory: URL, variables: [String: String]) throws
    func extractVariables(from content: String) -> [String]
}

// MARK: - Default Implementations

extension HotExitManager: HotExitService {}
extension LogManager: LoggingService {}
extension CommandTemplateManager: TemplateService {}
