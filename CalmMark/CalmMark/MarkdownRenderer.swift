//
//  MarkdownRenderer.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation

class MarkdownRenderer {

    // Render Markdown to HTML
    // This uses a basic implementation - can be enhanced with swift-markdown later
    static func renderToHTML(_ markdown: String, settings: AppSettings = AppSettings.shared) -> String {
        var html = markdown

        // Headers (# to ######)
        html = html.replacingOccurrences(
            of: "^#{6}\\s+(.+)$",
            with: "<h6>$1</h6>",
            options: .regularExpression,
            range: nil
        )
        html = html.replacingOccurrences(
            of: "^#{5}\\s+(.+)$",
            with: "<h5>$1</h5>",
            options: .regularExpression,
            range: nil
        )
        html = html.replacingOccurrences(
            of: "^#{4}\\s+(.+)$",
            with: "<h4>$1</h4>",
            options: .regularExpression,
            range: nil
        )
        html = html.replacingOccurrences(
            of: "^#{3}\\s+(.+)$",
            with: "<h3>$1</h3>",
            options: .regularExpression,
            range: nil
        )
        html = html.replacingOccurrences(
            of: "^#{2}\\s+(.+)$",
            with: "<h2>$1</h2>",
            options: .regularExpression,
            range: nil
        )
        html = html.replacingOccurrences(
            of: "^#\\s+(.+)$",
            with: "<h1>$1</h1>",
            options: .regularExpression,
            range: nil
        )

        // Code blocks (```language ... ```)
        html = renderCodeBlocks(html)

        // Inline code (`code`)
        html = html.replacingOccurrences(
            of: "`([^`]+)`",
            with: "<code>$1</code>",
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

        // Italic (*text* or _text_)
        html = html.replacingOccurrences(
            of: "\\*([^*]+)\\*",
            with: "<em>$1</em>",
            options: .regularExpression,
            range: nil
        )
        html = html.replacingOccurrences(
            of: "_([^_]+)_",
            with: "<em>$1</em>",
            options: .regularExpression,
            range: nil
        )

        // Links ([text](url))
        html = html.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)",
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression,
            range: nil
        )

        // Images (![alt](url))
        html = html.replacingOccurrences(
            of: "!\\[([^\\]]*)\\]\\(([^\\)]+)\\)",
            with: "<img src=\"$2\" alt=\"$1\" />",
            options: .regularExpression,
            range: nil
        )

        // Unordered lists (- item or * item)
        html = renderLists(html)

        // Blockquotes (> text)
        html = renderBlockquotes(html)

        // Horizontal rules (--- or ***)
        html = html.replacingOccurrences(
            of: "^(-{3,}|\\*{3,})$",
            with: "<hr />",
            options: .regularExpression,
            range: nil
        )

        // Paragraphs (wrap non-tagged lines)
        html = renderParagraphs(html)

        return wrapInHTML(html, settings: settings)
    }

    private static func renderCodeBlocks(_ text: String) -> String {
        var result = text
        let pattern = "```([a-zA-Z]*)\\n([\\s\\S]*?)```"

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))

            for match in matches.reversed() {
                if match.numberOfRanges == 3,
                   let languageRange = Range(match.range(at: 1), in: result),
                   let codeRange = Range(match.range(at: 2), in: result),
                   let fullRange = Range(match.range(at: 0), in: result) {

                    let language = String(result[languageRange])
                    let code = String(result[codeRange]).htmlEscaped
                    let replacement = "<pre><code class=\"language-\(language)\">\(code)</code></pre>"

                    result.replaceSubrange(fullRange, with: replacement)
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

        for line in lines {
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                if !inList {
                    output.append("<ul>")
                    inList = true
                }
                let item = line.dropFirst(2)
                output.append("<li>\(item)</li>")
            } else if line.hasPrefix("1. ") || line.range(of: "^\\d+\\.\\s", options: .regularExpression) != nil {
                if !inList {
                    output.append("<ol>")
                    inList = true
                }
                if let dotIndex = line.firstIndex(of: ".") {
                    let item = line[line.index(after: dotIndex)...].trimmingCharacters(in: .whitespaces)
                    output.append("<li>\(item)</li>")
                }
            } else {
                if inList {
                    // Close the list - check if it was ul or ol
                    let lastTag = output.last?.contains("<ul>") == true ? "</ul>" : "</ol>"
                    output.append(lastTag)
                    inList = false
                }
                output.append(line)
            }
        }

        if inList {
            let lastTag = output.last?.contains("<li>") == true ? "</ul>" : "</ol>"
            output.append(lastTag)
        }

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

            // Check if line is already HTML tagged
            let isTagged = trimmed.hasPrefix("<") && trimmed.hasSuffix(">")

            if trimmed.isEmpty {
                if !paragraphLines.isEmpty {
                    output.append("<p>\(paragraphLines.joined(separator: " "))</p>")
                    paragraphLines = []
                }
                output.append("")
            } else if isTagged {
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
