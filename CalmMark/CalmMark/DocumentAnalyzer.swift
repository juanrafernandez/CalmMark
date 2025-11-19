//
//  DocumentAnalyzer.swift
//  CalmMark
//
//  Analyzes markdown documents to extract structure and statistics
//

import Foundation
import Markdown

// MARK: - Heading Item

struct HeadingItem: Identifiable, Hashable {
    let id = UUID()
    let level: Int
    let text: String
    let lineNumber: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: HeadingItem, rhs: HeadingItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Document Statistics

struct DocumentStatistics {
    let wordCount: Int
    let characterCount: Int
    let characterCountNoSpaces: Int
    let lineCount: Int
    let paragraphCount: Int
    let headingCount: Int
    let linkCount: Int
    let imageCount: Int
    let codeBlockCount: Int
    let readingTimeMinutes: Int

    var readingTimeText: String {
        if readingTimeMinutes < 1 {
            return "< 1 min read"
        } else if readingTimeMinutes == 1 {
            return "1 min read"
        } else {
            return "\(readingTimeMinutes) min read"
        }
    }
}

// MARK: - Document Analyzer

class DocumentAnalyzer {

    // Extract headings for outline/navigation
    static func extractHeadings(from markdown: String) -> [HeadingItem] {
        let document = Document(parsing: markdown)
        var headings: [HeadingItem] = []

        extractHeadingsRecursive(from: document, into: &headings, sourceText: markdown)

        return headings
    }

    private static func extractHeadingsRecursive(from node: Markup, into headings: inout [HeadingItem], sourceText: String) {
        if let heading = node as? Heading {
            let text = extractPlainText(from: heading)
            let lineNumber = node.range?.lowerBound.line ?? 0

            headings.append(HeadingItem(
                level: heading.level,
                text: text,
                lineNumber: lineNumber
            ))
        }

        // Recursively process children
        for child in node.children {
            extractHeadingsRecursive(from: child, into: &headings, sourceText: sourceText)
        }
    }

    // Extract plain text from inline content
    private static func extractPlainText(from node: Markup) -> String {
        var text = ""

        if let textNode = node as? Text {
            return textNode.string
        }

        for child in node.children {
            text += extractPlainText(from: child)
        }

        return text
    }

    // Calculate document statistics
    static func analyzeDocument(_ markdown: String) -> DocumentStatistics {
        let document = Document(parsing: markdown)

        var wordCount = 0
        var paragraphCount = 0
        var headingCount = 0
        var linkCount = 0
        var imageCount = 0
        var codeBlockCount = 0

        analyzeNodeRecursive(document, stats: &(wordCount, paragraphCount, headingCount, linkCount, imageCount, codeBlockCount))

        let characterCount = markdown.count
        let characterCountNoSpaces = markdown.filter { !$0.isWhitespace }.count
        let lineCount = markdown.components(separatedBy: .newlines).count

        // Reading time: average 200-250 words per minute
        let readingTimeMinutes = max(1, Int(ceil(Double(wordCount) / 225.0)))

        return DocumentStatistics(
            wordCount: wordCount,
            characterCount: characterCount,
            characterCountNoSpaces: characterCountNoSpaces,
            lineCount: lineCount,
            paragraphCount: paragraphCount,
            headingCount: headingCount,
            linkCount: linkCount,
            imageCount: imageCount,
            codeBlockCount: codeBlockCount,
            readingTimeMinutes: readingTimeMinutes
        )
    }

    private static func analyzeNodeRecursive(
        _ node: Markup,
        stats: inout (words: Int, paragraphs: Int, headings: Int, links: Int, images: Int, codeBlocks: Int)
    ) {
        // Count elements
        if node is Paragraph {
            stats.paragraphs += 1
            let text = extractPlainText(from: node)
            stats.words += countWords(in: text)
        } else if node is Heading {
            stats.headings += 1
            let text = extractPlainText(from: node)
            stats.words += countWords(in: text)
        } else if node is Link {
            stats.links += 1
        } else if node is Image {
            stats.images += 1
        } else if node is CodeBlock {
            stats.codeBlocks += 1
        } else if let listItem = node as? ListItem {
            // Count words in list items
            let text = extractPlainText(from: listItem)
            stats.words += countWords(in: text)
        }

        // Recursively process children
        for child in node.children {
            analyzeNodeRecursive(child, stats: &stats)
        }
    }

    private static func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
}
