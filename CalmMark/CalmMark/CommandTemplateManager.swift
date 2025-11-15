//
//  CommandTemplateManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//  Manages templates for AI agent command files (.claude/commands/*.md)
//

import Foundation

struct CommandTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let filename: String
    let content: String
    let category: TemplateCategory
}

enum TemplateCategory: String, CaseIterable {
    case code = "Code"
    case documentation = "Documentation"
    case testing = "Testing"
    case git = "Git"
    case custom = "Custom"
}

class CommandTemplateManager {
    static let shared = CommandTemplateManager()

    let templates: [CommandTemplate] = [
        // Code Review Template
        CommandTemplate(
            name: "Code Review",
            description: "Review code changes for quality and best practices",
            filename: "review.md",
            category: .code,
            content: """
            # Code Review

            Review the following code changes:

            {{code}}

            Provide feedback on:
            - Code quality and readability
            - Potential bugs or issues
            - Performance considerations
            - Best practices
            - Security concerns

            Format your response with:
            1. Summary
            2. Issues found (if any)
            3. Suggestions for improvement
            """
        ),

        // Generate Tests Template
        CommandTemplate(
            name: "Generate Tests",
            description: "Generate unit tests for code",
            filename: "generate-tests.md",
            category: .testing,
            content: """
            # Generate Unit Tests

            Generate comprehensive unit tests for the following code:

            {{code}}

            Requirements:
            - Cover all public methods and functions
            - Include edge cases
            - Use appropriate test framework
            - Add descriptive test names
            - Include setup and teardown if needed

            Language: {{language}}
            Test Framework: {{framework}}
            """
        ),

        // Explain Code Template
        CommandTemplate(
            name: "Explain Code",
            description: "Get detailed explanation of code",
            filename: "explain.md",
            category: .code,
            content: """
            # Explain Code

            Please explain the following code in detail:

            {{code}}

            Include:
            - What the code does
            - How it works
            - Key concepts used
            - Potential improvements
            - Edge cases to consider

            Audience level: {{level}} (beginner/intermediate/advanced)
            """
        ),

        // Refactor Code Template
        CommandTemplate(
            name: "Refactor Code",
            description: "Suggest refactoring improvements",
            filename: "refactor.md",
            category: .code,
            content: """
            # Refactor Code

            Refactor the following code to improve:
            {{improvements}}

            Code:
            {{code}}

            Guidelines:
            - Maintain existing functionality
            - Improve readability
            - Follow best practices
            - Add comments where helpful
            - Consider performance

            Language: {{language}}
            """
        ),

        // Write Documentation Template
        CommandTemplate(
            name: "Write Documentation",
            description: "Generate documentation for code",
            filename: "document.md",
            category: .documentation,
            content: """
            # Write Documentation

            Generate comprehensive documentation for:

            {{code}}

            Include:
            - Overview/purpose
            - Parameters and return values
            - Usage examples
            - Edge cases and limitations
            - Related functions/classes

            Documentation style: {{style}} (JSDoc/Javadoc/Python docstring/etc)
            """
        ),

        // Git Commit Message Template
        CommandTemplate(
            name: "Generate Commit Message",
            description: "Create conventional commit messages",
            filename: "commit-message.md",
            category: .git,
            content: """
            # Generate Commit Message

            Generate a conventional commit message for the following changes:

            {{diff}}

            Format:
            ```
            <type>(<scope>): <subject>

            <body>

            <footer>
            ```

            Types: feat, fix, docs, style, refactor, test, chore

            Guidelines:
            - Use imperative mood
            - Keep subject under 50 chars
            - Explain what and why, not how
            """
        ),

        // Bug Fix Template
        CommandTemplate(
            name: "Fix Bug",
            description: "Analyze and fix bugs",
            filename: "fix-bug.md",
            category: .code,
            content: """
            # Fix Bug

            Bug Description:
            {{description}}

            Error Message:
            {{error}}

            Relevant Code:
            {{code}}

            Please:
            1. Analyze the root cause
            2. Provide a fix
            3. Explain why the bug occurred
            4. Suggest how to prevent similar bugs

            Language: {{language}}
            """
        ),

        // API Documentation Template
        CommandTemplate(
            name: "API Documentation",
            description: "Generate API endpoint documentation",
            filename: "api-docs.md",
            category: .documentation,
            content: """
            # API Documentation

            Generate documentation for the following API endpoint:

            {{code}}

            Include:
            - Endpoint URL and method
            - Request parameters
            - Request body schema
            - Response schema
            - Status codes
            - Example requests/responses
            - Authentication requirements
            - Rate limiting

            Format: {{format}} (OpenAPI/Markdown/etc)
            """
        ),

        // Code Optimization Template
        CommandTemplate(
            name: "Optimize Performance",
            description: "Suggest performance optimizations",
            filename: "optimize.md",
            category: .code,
            content: """
            # Performance Optimization

            Optimize the following code for better performance:

            {{code}}

            Focus areas:
            {{focus}}

            Consider:
            - Time complexity
            - Space complexity
            - I/O operations
            - Caching opportunities
            - Parallel processing

            Target: {{target}} (speed/memory/both)
            Language: {{language}}
            """
        ),

        // README Generator Template
        CommandTemplate(
            name: "Generate README",
            description: "Create comprehensive README files",
            filename: "readme-generator.md",
            category: .documentation,
            content: """
            # Generate README

            Generate a comprehensive README.md for the following project:

            Project Name: {{name}}
            Description: {{description}}

            Include sections:
            - Project title and badges
            - Description
            - Features
            - Installation
            - Usage examples
            - Configuration
            - Contributing guidelines
            - License
            - Contact/Support

            Tone: {{tone}} (professional/casual/technical)
            """
        )
    ]

    func getTemplatesByCategory(_ category: TemplateCategory) -> [CommandTemplate] {
        templates.filter { $0.category == category }
    }

    func createCommandFile(
        from template: CommandTemplate,
        in directory: URL,
        variables: [String: String] = [:]
    ) throws {
        var content = template.content

        // Replace variables
        for (key, value) in variables {
            content = content.replacingOccurrences(of: "{{\(key)}}", with: value)
        }

        let fileURL = directory.appendingPathComponent(template.filename)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // Extract variables from template content
    func extractVariables(from content: String) -> [String] {
        let pattern = "\\{\\{([^}]+)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)

        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: content) else {
                return nil
            }
            return String(content[range])
        }
    }

    // Check if file is a Claude command
    static func isClaudeCommand(_ url: URL) -> Bool {
        let components = url.pathComponents
        return components.contains(".claude") &&
               components.contains("commands") &&
               url.pathExtension == "md"
    }

    // Get .claude/commands directory or create it
    static func getCommandsDirectory(in rootURL: URL) throws -> URL {
        let claudeDir = rootURL.appendingPathComponent(".claude")
        let commandsDir = claudeDir.appendingPathComponent("commands")

        if !FileManager.default.fileExists(atPath: commandsDir.path) {
            try FileManager.default.createDirectory(
                at: commandsDir,
                withIntermediateDirectories: true
            )
        }

        return commandsDir
    }
}
