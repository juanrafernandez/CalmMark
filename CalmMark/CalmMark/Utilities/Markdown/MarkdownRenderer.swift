//
//  MarkdownRenderer.swift
//  CalmMark
//
//  Refactored to use swift-markdown for precise line number mapping
//

import Foundation
import Markdown

class MarkdownRenderer {

    // Render Markdown to HTML using swift-markdown
    static func renderToHTML(_ markdown: String, settings: AppSettings = AppSettings.shared) -> String {
        // Parse markdown using swift-markdown
        let document = Document(parsing: markdown)

        // Generate HTML from the AST with line numbers
        let htmlBody = HTMLRenderer.render(document, sourceText: markdown)

        return wrapInHTML(htmlBody, settings: settings)
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

// MARK: - HTML Renderer

private struct HTMLRenderer {

    static func render(_ document: Document, sourceText: String) -> String {
        var html = ""
        var elementsProcessed = 0

        LogManager.shared.log(.debug, "🔢 Renderizando con swift-markdown", context: "Renderer")

        for child in document.children {
            html += renderNode(child, sourceText: sourceText, elementsProcessed: &elementsProcessed)
        }

        LogManager.shared.log(.success, "✅ Total elementos con data-source-line: \(elementsProcessed)", context: "Renderer")

        return html
    }

    private static func renderNode(_ node: Markup, sourceText: String, elementsProcessed: inout Int) -> String {
        // Get line number from node's source range
        let lineNumber = getLineNumber(for: node, sourceText: sourceText)

        switch node {
        case let heading as Heading:
            return renderHeading(heading, lineNumber: lineNumber, sourceText: sourceText, elementsProcessed: &elementsProcessed)

        case let paragraph as Paragraph:
            return renderParagraph(paragraph, lineNumber: lineNumber, sourceText: sourceText, elementsProcessed: &elementsProcessed)

        case let list as UnorderedList:
            return renderUnorderedList(list, sourceText: sourceText, elementsProcessed: &elementsProcessed)

        case let list as OrderedList:
            return renderOrderedList(list, sourceText: sourceText, elementsProcessed: &elementsProcessed)

        case let listItem as ListItem:
            return renderListItem(listItem, sourceText: sourceText, elementsProcessed: &elementsProcessed)

        case let blockQuote as BlockQuote:
            return renderBlockQuote(blockQuote, lineNumber: lineNumber, sourceText: sourceText, elementsProcessed: &elementsProcessed)

        case let codeBlock as CodeBlock:
            return renderCodeBlock(codeBlock, lineNumber: lineNumber, elementsProcessed: &elementsProcessed)

        case let thematicBreak as ThematicBreak:
            return "<hr />\n"

        case let table as Table:
            return renderTable(table, lineNumber: lineNumber, sourceText: sourceText, elementsProcessed: &elementsProcessed)

        default:
            // For unknown block elements, process children
            var html = ""
            for child in node.children {
                html += renderNode(child, sourceText: sourceText, elementsProcessed: &elementsProcessed)
            }
            return html
        }
    }

    // MARK: - Block Elements

    private static func renderHeading(_ heading: Heading, lineNumber: Int?, sourceText: String, elementsProcessed: inout Int) -> String {
        let level = heading.level
        let content = renderInlineContent(heading.children, sourceText: sourceText)

        if let lineNumber = lineNumber {
            elementsProcessed += 1
            return "<h\(level) data-source-line=\"\(lineNumber)\" class=\"line\">\(content)</h\(level)>\n"
        } else {
            return "<h\(level)>\(content)</h\(level)>\n"
        }
    }

    private static func renderParagraph(_ paragraph: Paragraph, lineNumber: Int?, sourceText: String, elementsProcessed: inout Int) -> String {
        let content = renderInlineContent(paragraph.children, sourceText: sourceText)

        if let lineNumber = lineNumber {
            elementsProcessed += 1
            return "<p data-source-line=\"\(lineNumber)\" class=\"line\">\(content)</p>\n"
        } else {
            return "<p>\(content)</p>\n"
        }
    }

    private static func renderUnorderedList(_ list: UnorderedList, sourceText: String, elementsProcessed: inout Int) -> String {
        var html = "<ul>\n"

        for child in list.children {
            html += renderNode(child, sourceText: sourceText, elementsProcessed: &elementsProcessed)
        }

        html += "</ul>\n"
        return html
    }

    private static func renderOrderedList(_ list: OrderedList, sourceText: String, elementsProcessed: inout Int) -> String {
        var html = "<ol>\n"

        for child in list.children {
            html += renderNode(child, sourceText: sourceText, elementsProcessed: &elementsProcessed)
        }

        html += "</ol>\n"
        return html
    }

    private static func renderListItem(_ item: ListItem, sourceText: String, elementsProcessed: inout Int) -> String {
        let lineNumber = getLineNumber(for: item, sourceText: sourceText)
        var content = ""

        for child in item.children {
            content += renderNode(child, sourceText: sourceText, elementsProcessed: &elementsProcessed)
        }

        // Remove wrapping <p> tags from list items (markdown convention)
        var cleanContent = content
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for task list checkbox (GFM extension)
        var isTaskList = false
        var isChecked = false

        if cleanContent.hasPrefix("[ ] ") {
            isTaskList = true
            isChecked = false
            cleanContent = String(cleanContent.dropFirst(4))
        } else if cleanContent.hasPrefix("[x] ") || cleanContent.hasPrefix("[X] ") {
            isTaskList = true
            isChecked = true
            cleanContent = String(cleanContent.dropFirst(4))
        }

        // Render task list with checkbox
        if isTaskList {
            let checkbox = isChecked
                ? "<input type=\"checkbox\" checked disabled class=\"task-list-checkbox\" />"
                : "<input type=\"checkbox\" disabled class=\"task-list-checkbox\" />"

            if let lineNumber = lineNumber {
                elementsProcessed += 1
                return "<li data-source-line=\"\(lineNumber)\" class=\"line task-list-item\">\(checkbox) \(cleanContent)</li>\n"
            } else {
                return "<li class=\"task-list-item\">\(checkbox) \(cleanContent)</li>\n"
            }
        }

        // Regular list item
        if let lineNumber = lineNumber {
            elementsProcessed += 1
            return "<li data-source-line=\"\(lineNumber)\" class=\"line\">\(cleanContent)</li>\n"
        } else {
            return "<li>\(cleanContent)</li>\n"
        }
    }

    private static func renderBlockQuote(_ blockQuote: BlockQuote, lineNumber: Int?, sourceText: String, elementsProcessed: inout Int) -> String {
        var content = ""

        for child in blockQuote.children {
            content += renderNode(child, sourceText: sourceText, elementsProcessed: &elementsProcessed)
        }

        if let lineNumber = lineNumber {
            elementsProcessed += 1
            return "<blockquote data-source-line=\"\(lineNumber)\" class=\"line\">\n\(content)</blockquote>\n"
        } else {
            return "<blockquote>\n\(content)</blockquote>\n"
        }
    }

    private static func renderCodeBlock(_ codeBlock: CodeBlock, lineNumber: Int?, elementsProcessed: inout Int) -> String {
        let language = codeBlock.language ?? ""
        let code = codeBlock.code.htmlEscaped

        if let lineNumber = lineNumber {
            elementsProcessed += 1
            return "<pre data-source-line=\"\(lineNumber)\" class=\"line\"><code class=\"language-\(language)\">\(code)</code></pre>\n"
        } else {
            return "<pre><code class=\"language-\(language)\">\(code)</code></pre>\n"
        }
    }

    private static func renderTable(_ table: Table, lineNumber: Int?, sourceText: String, elementsProcessed: inout Int) -> String {
        var html = ""

        if let lineNumber = lineNumber {
            elementsProcessed += 1
            html += "<table data-source-line=\"\(lineNumber)\" class=\"line\">\n"
        } else {
            html += "<table>\n"
        }

        // Render table head
        let head = table.head
        html += "<thead>\n"
        for row in head.children {
            html += renderTableRow(row, sourceText: sourceText, isHeader: true)
        }
        html += "</thead>\n"

        // Render table body
        let body = table.body
        html += "<tbody>\n"
        for row in body.children {
            html += renderTableRow(row, sourceText: sourceText, isHeader: false)
        }
        html += "</tbody>\n"

        html += "</table>\n"
        return html
    }

    private static func renderTableRow(_ row: Markup, sourceText: String, isHeader: Bool) -> String {
        var html = "<tr>\n"

        for cell in row.children {
            if isHeader {
                html += "<th>"
            } else {
                html += "<td>"
            }

            // Render cell content as inline markdown
            var cellContent = ""
            for child in cell.children {
                cellContent += renderInlineNode(child, sourceText: sourceText)
            }
            html += cellContent

            if isHeader {
                html += "</th>\n"
            } else {
                html += "</td>\n"
            }
        }

        html += "</tr>\n"
        return html
    }

    // MARK: - Inline Elements

    private static func renderInlineContent(_ children: some Sequence<Markup>, sourceText: String) -> String {
        var html = ""

        for child in children {
            html += renderInlineNode(child, sourceText: sourceText)
        }

        return html
    }

    private static func renderInlineNode(_ node: Markup, sourceText: String) -> String {
        switch node {
        case let text as Text:
            return text.string.htmlEscaped

        case let strong as Strong:
            let content = renderInlineContent(strong.children, sourceText: sourceText)
            return "<strong>\(content)</strong>"

        case let emphasis as Emphasis:
            let content = renderInlineContent(emphasis.children, sourceText: sourceText)
            return "<em>\(content)</em>"

        case let code as InlineCode:
            return "<code>\(code.code.htmlEscaped)</code>"

        case let link as Link:
            let content = renderInlineContent(link.children, sourceText: sourceText)
            let destination = link.destination ?? ""
            return "<a href=\"\(destination)\" target=\"_blank\" rel=\"noopener noreferrer\">\(content)</a>"

        case let image as Image:
            let alt = image.plainText
            let source = image.source ?? ""
            return "<img src=\"\(source)\" alt=\"\(alt)\" loading=\"lazy\" />"

        case let strikethrough as Strikethrough:
            let content = renderInlineContent(strikethrough.children, sourceText: sourceText)
            return "<del>\(content)</del>"

        case let softBreak as SoftBreak:
            return " "

        case let lineBreak as LineBreak:
            return "<br />"

        default:
            // For unknown inline elements, render children
            var html = ""
            for child in node.children {
                html += renderInlineNode(child, sourceText: sourceText)
            }
            return html
        }
    }

    // MARK: - Line Number Extraction

    private static func getLineNumber(for node: Markup, sourceText: String) -> Int? {
        guard let range = node.range else { return nil }

        // SourceLocation already contains the line number (1-based)
        return range.lowerBound.line
    }
}

// MARK: - String Extension

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
