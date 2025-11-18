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
    // Process ALL elements in HTML document order to maintain sequential line mapping
    private static func addSourceLineNumbers(_ html: String, markdown: String) -> String {
        let markdownLines = markdown.components(separatedBy: .newlines)
        var result = html

        LogManager.shared.log(.debug, "🔢 Añadiendo números de línea: \(markdownLines.count) líneas markdown", context: "Renderer")

        // Helper to extract ALL text from any HTML string (including nested tags)
        func extractAllText(_ htmlString: String) -> String {
            var text = htmlString
            // Remove ALL HTML tags recursively
            while text.contains("<") {
                text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            }
            // Decode HTML entities
            text = text.replacingOccurrences(of: "&amp;", with: "&")
            text = text.replacingOccurrences(of: "&lt;", with: "<")
            text = text.replacingOccurrences(of: "&gt;", with: ">")
            text = text.replacingOccurrences(of: "&quot;", with: "\"")
            text = text.replacingOccurrences(of: "&#39;", with: "'")
            // Normalize whitespace
            text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Helper to find markdown line containing text, searching from a start line
        func findMarkdownLine(containing searchText: String, startingFrom startLine: Int) -> Int? {
            guard !searchText.isEmpty, searchText.count >= 3 else { return nil }

            // Take first 30 chars for matching
            let needle = String(searchText.prefix(30)).lowercased()

            // Search from startLine forward
            for index in startLine..<markdownLines.count {
                let line = markdownLines[index]
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

                // Skip empty lines
                if cleanLine.isEmpty { continue }

                // Remove common markdown syntax
                let strippedLine = cleanLine
                    .replacingOccurrences(of: "^#{1,6}\\s+", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "^>\\s+", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "^[-*+]\\s+(?:\\[[ xX]\\]\\s+)?", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "^\\d+\\.\\s+", with: "", options: .regularExpression)
                    .lowercased()

                // Check if text matches (fuzzy)
                if strippedLine.contains(needle) || needle.contains(strippedLine) {
                    return index + 1 // 1-based
                }
            }
            return nil
        }

        // Structure to hold element info
        struct ElementMatch {
            let location: Int
            let fullRange: Range<String.Index>
            let contentRange: Range<String.Index>?
            let type: String
            let tagPattern: String
        }

        // Collect ALL elements with their positions in the HTML
        var allElements: [ElementMatch] = []

        // Headers (h1-h6)
        for level in 1...6 {
            let pattern = "<h\(level)(?:\\s[^>]*)?>([\\s\\S]*?)</h\(level)>"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))
                for match in matches {
                    if let fullRange = Range(match.range(at: 0), in: result),
                       let contentRange = Range(match.range(at: 1), in: result) {
                        let fullMatch = String(result[fullRange])
                        if !fullMatch.contains("data-source-line") {
                            allElements.append(ElementMatch(
                                location: match.range(at: 0).location,
                                fullRange: fullRange,
                                contentRange: contentRange,
                                type: "h\(level)",
                                tagPattern: "<h\(level)(?:\\s[^>]*)?>")
                            )
                        }
                    }
                }
            }
        }

        // Paragraphs
        let pPattern = "<p(?:\\s[^>]*)?>([\\s\\S]*?)</p>"
        if let regex = try? NSRegularExpression(pattern: pPattern, options: []) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))
            for match in matches {
                if let fullRange = Range(match.range(at: 0), in: result),
                   let contentRange = Range(match.range(at: 1), in: result) {
                    let fullMatch = String(result[fullRange])
                    if !fullMatch.contains("data-source-line") {
                        allElements.append(ElementMatch(
                            location: match.range(at: 0).location,
                            fullRange: fullRange,
                            contentRange: contentRange,
                            type: "p",
                            tagPattern: "<p(?:\\s[^>]*)?>")
                        )
                    }
                }
            }
        }

        // List items
        let liPattern = "<li(?:\\s[^>]*)?>([\\s\\S]*?)</li>"
        if let regex = try? NSRegularExpression(pattern: liPattern, options: []) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))
            for match in matches {
                if let fullRange = Range(match.range(at: 0), in: result),
                   let contentRange = Range(match.range(at: 1), in: result) {
                    let fullMatch = String(result[fullRange])
                    if !fullMatch.contains("data-source-line") {
                        allElements.append(ElementMatch(
                            location: match.range(at: 0).location,
                            fullRange: fullRange,
                            contentRange: contentRange,
                            type: "li",
                            tagPattern: "<li(?:\\s[^>]*)?>")
                        )
                    }
                }
            }
        }

        // Blockquotes
        let blockquotePattern = "<blockquote(?:\\s[^>]*)?>([\\s\\S]*?)</blockquote>"
        if let regex = try? NSRegularExpression(pattern: blockquotePattern, options: []) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))
            for match in matches {
                if let fullRange = Range(match.range(at: 0), in: result),
                   let contentRange = Range(match.range(at: 1), in: result) {
                    let fullMatch = String(result[fullRange])
                    if !fullMatch.contains("data-source-line") {
                        allElements.append(ElementMatch(
                            location: match.range(at: 0).location,
                            fullRange: fullRange,
                            contentRange: contentRange,
                            type: "blockquote",
                            tagPattern: "<blockquote(?:\\s[^>]*)?>")
                        )
                    }
                }
            }
        }

        // Code blocks - special handling (no content extraction needed)
        let prePattern = "<pre(?:\\s[^>]*)?>([\\s\\S]*?)</pre>"
        if let regex = try? NSRegularExpression(pattern: prePattern, options: []) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))
            for match in matches {
                if let fullRange = Range(match.range(at: 0), in: result) {
                    let fullMatch = String(result[fullRange])
                    if !fullMatch.contains("data-source-line") {
                        allElements.append(ElementMatch(
                            location: match.range(at: 0).location,
                            fullRange: fullRange,
                            contentRange: nil,
                            type: "pre",
                            tagPattern: "<pre(?:\\s[^>]*)?>")
                        )
                    }
                }
            }
        }

        // Sort by position in HTML document
        allElements.sort { $0.location < $1.location }

        LogManager.shared.log(.debug, "📦 Total elementos encontrados: \(allElements.count)", context: "Renderer")

        // FIRST: Build line number mappings by going FORWARD through elements
        var elementLineMap: [Int: Int] = [:] // element index → line number
        var currentSearchLine = 0  // 0-based index

        for (index, element) in allElements.enumerated() {
            var lineNum: Int? = nil

            if element.type == "pre" {
                // Special handling for code blocks - find next ``` after current search line
                for lineIndex in currentSearchLine..<markdownLines.count {
                    if markdownLines[lineIndex].contains("```") {
                        lineNum = lineIndex + 1 // 1-based
                        currentSearchLine = lineIndex + 1 // Move past this code block
                        break
                    }
                }
            } else if let contentRange = element.contentRange {
                // Extract and search for text content
                let content = String(result[contentRange])
                let textContent = extractAllText(content)
                lineNum = findMarkdownLine(containing: textContent, startingFrom: currentSearchLine)

                // Update search position for next element
                if let found = lineNum {
                    currentSearchLine = found // Next search starts from found line
                }
            }

            if let lineNum = lineNum {
                elementLineMap[index] = lineNum
            }
        }

        // SECOND: Apply replacements in REVERSE order to avoid breaking string indices
        var elementsProcessed = 0
        var counters = ["h1": 0, "h2": 0, "h3": 0, "h4": 0, "h5": 0, "h6": 0, "p": 0, "li": 0, "blockquote": 0, "pre": 0]

        for (index, element) in allElements.enumerated().reversed() {
            if let lineNum = elementLineMap[index] {
                let fullMatch = String(result[element.fullRange])

                // Create replacement with data-source-line attribute
                let replacement = fullMatch.replacingOccurrences(
                    of: element.tagPattern,
                    with: "<\(element.type) data-source-line=\"\(lineNum)\" class=\"line\">",
                    options: .regularExpression,
                    range: nil
                )
                result.replaceSubrange(element.fullRange, with: replacement)
                elementsProcessed += 1
                counters[element.type, default: 0] += 1
            }
        }

        // Log summary
        LogManager.shared.log(.debug, "📋 Headers (h1-h6): \(counters["h1"]! + counters["h2"]! + counters["h3"]! + counters["h4"]! + counters["h5"]! + counters["h6"]!)", context: "Renderer")
        LogManager.shared.log(.debug, "📋 Párrafos: \(counters["p"]!)", context: "Renderer")
        LogManager.shared.log(.debug, "📋 List items: \(counters["li"]!)", context: "Renderer")
        LogManager.shared.log(.debug, "📋 Blockquotes: \(counters["blockquote"]!)", context: "Renderer")
        LogManager.shared.log(.debug, "📋 Code blocks: \(counters["pre"]!)", context: "Renderer")
        LogManager.shared.log(.success, "✅ Total elementos con data-source-line: \(elementsProcessed)", context: "Renderer")

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
