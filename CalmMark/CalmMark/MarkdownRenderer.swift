//
//  MarkdownRenderer.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation

class MarkdownRenderer {

    // Storage for code blocks during processing
    private static var codeBlockPlaceholders: [String: String] = [:]
    private static var placeholderCounter = 0

    // Render Markdown to HTML
    // This uses a basic implementation - can be enhanced with swift-markdown later
    static func renderToHTML(_ markdown: String, settings: AppSettings = AppSettings.shared) -> String {
        var html = markdown

        // Reset placeholders
        codeBlockPlaceholders = [:]
        placeholderCounter = 0

        // Code blocks FIRST (to protect code from other transformations)
        html = renderCodeBlocks(html)

        // Headers (# to ######) - Use (?m) for multiline mode
        for level in (1...6).reversed() {
            let hashes = String(repeating: "#", count: level)
            let pattern = "(?m)^\(hashes)\\s+(.+)$"
            html = html.replacingOccurrences(
                of: pattern,
                with: "<h\(level)>$1</h\(level)>",
                options: .regularExpression,
                range: nil
            )
        }

        // Horizontal rules BEFORE other inline elements
        html = html.replacingOccurrences(
            of: "(?m)^(-{3,}|\\*{3,}|_{3,})$",
            with: "<hr />",
            options: .regularExpression,
            range: nil
        )

        // Images BEFORE links (because ![...](url) contains [...](url))
        html = html.replacingOccurrences(
            of: "!\\[([^\\]]*)\\]\\(([^\\)]+)\\)",
            with: "<img src=\"$2\" alt=\"$1\" loading=\"lazy\" />",
            options: .regularExpression,
            range: nil
        )

        // Links
        html = html.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)",
            with: "<a href=\"$2\" target=\"_blank\" rel=\"noopener noreferrer\">$1</a>",
            options: .regularExpression,
            range: nil
        )

        // Bold (**text** or __text__)
        html = html.replacingOccurrences(
            of: "\\*\\*([^*]+)\\*\\*",
            with: "<strong>$1</strong>",
            options: .regularExpression,
            range: nil
        )
        html = html.replacingOccurrences(
            of: "__([^_]+)__",
            with: "<strong>$1</strong>",
            options: .regularExpression,
            range: nil
        )

        // Strikethrough (~~text~~)
        html = html.replacingOccurrences(
            of: "~~([^~]+)~~",
            with: "<del>$1</del>",
            options: .regularExpression,
            range: nil
        )

        // Italic (*text* or _text_) - AFTER bold to avoid conflicts
        html = html.replacingOccurrences(
            of: "(?<!\\*)\\*([^*]+)\\*(?!\\*)",
            with: "<em>$1</em>",
            options: .regularExpression,
            range: nil
        )
        html = html.replacingOccurrences(
            of: "(?<!_)_([^_]+)_(?!_)",
            with: "<em>$1</em>",
            options: .regularExpression,
            range: nil
        )

        // Inline code (`code`)
        html = html.replacingOccurrences(
            of: "`([^`]+)`",
            with: "<code>$1</code>",
            options: .regularExpression,
            range: nil
        )

        // Lists
        html = renderLists(html)

        // Blockquotes
        html = renderBlockquotes(html)

        // Paragraphs (wrap non-tagged lines)
        html = renderParagraphs(html)

        // Restore code blocks from placeholders
        html = restoreCodeBlocks(html)

        // Add line numbers to HTML elements
        html = addSourceLineNumbers(html, markdown: markdown)

        return wrapInHTML(html, settings: settings)
    }

    // Post-process HTML to add data-source-line attributes
    private static func addSourceLineNumbers(_ html: String, markdown: String) -> String {
        let markdownLines = markdown.components(separatedBy: .newlines)
        var result = html

        // Helper to extract text content from HTML tag
        func extractTextContent(_ htmlString: String) -> String {
            var text = htmlString
            // Remove HTML tags
            text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            // Decode HTML entities
            text = text.replacingOccurrences(of: "&amp;", with: "&")
            text = text.replacingOccurrences(of: "&lt;", with: "<")
            text = text.replacingOccurrences(of: "&gt;", with: ">")
            text = text.replacingOccurrences(of: "&quot;", with: "\"")
            text = text.replacingOccurrences(of: "&#39;", with: "'")
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Helper to find markdown line containing text
        func findMarkdownLine(containing text: String) -> Int? {
            guard !text.isEmpty else { return nil }

            for (index, line) in markdownLines.enumerated() {
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                // Check if markdown line contains the text (accounting for markdown syntax)
                if cleanLine.contains(text) ||
                   cleanLine.replacingOccurrences(of: "^#{1,6}\\s+", with: "", options: .regularExpression).contains(text) ||
                   cleanLine.replacingOccurrences(of: "^>\\s+", with: "", options: .regularExpression).contains(text) ||
                   cleanLine.replacingOccurrences(of: "^[-*+]\\s+", with: "", options: .regularExpression).contains(text) ||
                   cleanLine.replacingOccurrences(of: "^\\d+\\.\\s+", with: "", options: .regularExpression).contains(text) {
                    return index + 1 // Line numbers are 1-based
                }
            }
            return nil
        }

        // Process headers (h1-h6)
        for level in 1...6 {
            let pattern = "<h\(level)>([^<]+)</h\(level)>"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))

                for match in matches.reversed() {
                    if match.numberOfRanges >= 2,
                       let fullRange = Range(match.range(at: 0), in: result),
                       let contentRange = Range(match.range(at: 1), in: result) {

                        let fullMatch = String(result[fullRange])
                        let content = String(result[contentRange])
                        let textContent = extractTextContent(content)

                        if let lineNum = findMarkdownLine(containing: textContent) {
                            let replacement = "<h\(level) data-source-line=\"\(lineNum)\">\(content)</h\(level)>"
                            result.replaceSubrange(fullRange, with: replacement)
                        }
                    }
                }
            }
        }

        // Process paragraphs
        let pPattern = "<p>([^<]+(?:<[^/][^>]*>[^<]*</[^>]+>)*[^<]*)</p>"
        if let regex = try? NSRegularExpression(pattern: pPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))

            for match in matches.reversed() {
                if match.numberOfRanges >= 2,
                   let fullRange = Range(match.range(at: 0), in: result),
                   let contentRange = Range(match.range(at: 1), in: result) {

                    let fullMatch = String(result[fullRange])
                    let content = String(result[contentRange])
                    let textContent = extractTextContent(content)

                    // Only process if not already has data-source-line
                    if !fullMatch.contains("data-source-line"),
                       let lineNum = findMarkdownLine(containing: textContent) {
                        let replacement = "<p data-source-line=\"\(lineNum)\">\(content)</p>"
                        result.replaceSubrange(fullRange, with: replacement)
                    }
                }
            }
        }

        // Process code blocks
        let prePattern = "<pre>(<code[^>]*>.*?</code>)</pre>"
        if let regex = try? NSRegularExpression(pattern: prePattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))

            for match in matches.reversed() {
                if match.numberOfRanges >= 2,
                   let fullRange = Range(match.range(at: 0), in: result) {

                    let fullMatch = String(result[fullRange])

                    // Only process if not already has data-source-line
                    if !fullMatch.contains("data-source-line") {
                        // Find line with ``` in markdown
                        if let lineNum = markdownLines.firstIndex(where: { $0.contains("```") }) {
                            let content = fullMatch.replacingOccurrences(of: "<pre>", with: "")
                                                   .replacingOccurrences(of: "</pre>", with: "")
                            let replacement = "<pre data-source-line=\"\(lineNum + 1)\">\(content)</pre>"
                            result.replaceSubrange(fullRange, with: replacement)
                        }
                    }
                }
            }
        }

        return result
    }

    private static func restoreCodeBlocks(_ text: String) -> String {
        var result = text
        for (placeholder, codeBlock) in codeBlockPlaceholders {
            result = result.replacingOccurrences(of: placeholder, with: codeBlock)
        }
        return result
    }

    private static func renderCodeBlocks(_ text: String) -> String {
        var result = text
        // Updated pattern to match GFM spec:
        // - Optional indentation (0-3 spaces)
        // - 3+ backticks
        // - Optional info string (language)
        // - Content
        // - Closing fence with same or more backticks
        let pattern = "^[ ]{0,3}```([a-zA-Z0-9]*)[ ]*\\n([\\s\\S]*?)^[ ]{0,3}```[ ]*$"

        if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))

            for match in matches.reversed() {
                if match.numberOfRanges == 3,
                   let languageRange = Range(match.range(at: 1), in: result),
                   let codeRange = Range(match.range(at: 2), in: result),
                   let fullRange = Range(match.range(at: 0), in: result) {

                    let language = String(result[languageRange])
                    var code = String(result[codeRange])

                    // Remove trailing newline if present (the one before closing ```)
                    if code.hasSuffix("\n") {
                        code = String(code.dropLast())
                    }

                    // Preserve newlines by escaping HTML
                    code = code.htmlEscaped

                    // Create HTML block - preserve all whitespace including newlines
                    let codeBlock = "<pre><code class=\"language-\(language)\">\(code)</code></pre>"

                    // Create unique placeholder using HTML comment format to avoid markdown processing
                    let placeholder = "<!--CODEBLOCK\(placeholderCounter)-->"
                    placeholderCounter += 1

                    // Store the actual code block
                    codeBlockPlaceholders[placeholder] = codeBlock

                    // Replace with placeholder
                    result.replaceSubrange(fullRange, with: placeholder)
                }
            }
        }

        return result
    }

    private static func renderLists(_ text: String) -> String {
        var result = text
        let lines = result.components(separatedBy: .newlines)
        var output: [String] = []
        var inList = false
        var listType = ""
        var inListItem = false
        var listItemContent: [String] = []

        func closeListItem() {
            if inListItem {
                output.append(listItemContent.joined(separator: "\n") + "</li>")
                listItemContent = []
                inListItem = false
            }
        }

        func closeList() {
            closeListItem()
            if inList {
                if listType == "task" || listType == "ul" {
                    output.append("</ul>")
                } else {
                    output.append("</ol>")
                }
                inList = false
                listType = ""
            }
        }

        for i in 0..<lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isIndented = line.hasPrefix(" ") || line.hasPrefix("\t")
            let isPlaceholder = line.contains("<!--CODEBLOCK")

            // Task lists (- [ ] or - [x])
            if line.hasPrefix("- [ ] ") || line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") {
                if !inList || listType != "task" {
                    closeList()
                    output.append("<ul class=\"task-list\">")
                    inList = true
                    listType = "task"
                } else {
                    closeListItem()
                }
                let checked = line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ")
                let item = line.dropFirst(6) // Skip "- [x] "
                let checkbox = checked ? "<input type=\"checkbox\" checked disabled />" : "<input type=\"checkbox\" disabled />"
                listItemContent = ["<li class=\"task-list-item\">\(checkbox) \(item)"]
                inListItem = true
            }
            // Regular unordered lists
            else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                if !inList || listType != "ul" {
                    closeList()
                    output.append("<ul>")
                    inList = true
                    listType = "ul"
                } else {
                    closeListItem()
                }
                let item = line.dropFirst(2)
                listItemContent = ["<li>\(item)"]
                inListItem = true
            }
            // Ordered lists (match any number followed by .)
            else if line.range(of: "^\\d+\\.\\s", options: .regularExpression) != nil {
                if !inList || listType != "ol" {
                    closeList()
                    output.append("<ol>")
                    inList = true
                    listType = "ol"
                } else {
                    closeListItem()
                }
                if let dotIndex = line.firstIndex(of: ".") {
                    let item = line[line.index(after: dotIndex)...].trimmingCharacters(in: .whitespaces)
                    listItemContent = ["<li>\(item)"]
                    inListItem = true
                }
            }
            // If we're in a list item and this is indented content, placeholder, or HTML, add to item
            else if inListItem && (isIndented || isPlaceholder || trimmed.hasPrefix("<") || trimmed.isEmpty) {
                listItemContent.append(line)
            }
            // Non-list content
            else {
                closeList()
                output.append(line)
            }
        }

        // Close any remaining open items/lists
        closeList()

        return output.joined(separator: "\n")
    }

    private static func renderBlockquotes(_ text: String) -> String {
        var result = text
        let lines = result.components(separatedBy: .newlines)
        var output: [String] = []
        var inBlockquote = false
        var blockquoteContent: [String] = []

        for line in lines {
            if line.hasPrefix("> ") {
                if !inBlockquote {
                    inBlockquote = true
                }
                blockquoteContent.append(String(line.dropFirst(2)))
            } else {
                if inBlockquote {
                    output.append("<blockquote>\n\(blockquoteContent.joined(separator: "\n"))\n</blockquote>")
                    blockquoteContent = []
                    inBlockquote = false
                }
                output.append(line)
            }
        }

        if inBlockquote {
            output.append("<blockquote>\n\(blockquoteContent.joined(separator: "\n"))\n</blockquote>")
        }

        return output.joined(separator: "\n")
    }

    private static func renderParagraphs(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var output: [String] = []
        var paragraphLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check if line is already HTML tagged or is a code block placeholder
            let isTagged = trimmed.hasPrefix("<") && trimmed.hasSuffix(">")
            let isPlaceholder = trimmed.contains("<!--CODEBLOCK")

            if trimmed.isEmpty {
                if !paragraphLines.isEmpty {
                    output.append("<p>\(paragraphLines.joined(separator: " "))</p>")
                    paragraphLines = []
                }
                output.append("")
            } else if isTagged || isPlaceholder {
                if !paragraphLines.isEmpty {
                    output.append("<p>\(paragraphLines.joined(separator: " "))</p>")
                    paragraphLines = []
                }
                output.append(line)
            } else {
                paragraphLines.append(trimmed)
            }
        }

        if !paragraphLines.isEmpty {
            output.append("<p>\(paragraphLines.joined(separator: " "))</p>")
        }

        return output.joined(separator: "\n")
    }

    private static func wrapInHTML(_ body: String, settings: AppSettings) -> String {
        let css = StylesheetGenerator.generateCSS(for: settings)

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>CalmMark Preview</title>
            <style>
            \(css)
            </style>
        </head>
        <body>
            <div class="container">
                \(body)
            </div>
        </body>
        </html>
        """
    }
}

extension String {
    var htmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
