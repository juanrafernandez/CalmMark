//
//  StylesheetGenerator.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation

class StylesheetGenerator {

    static func generateCSS(for settings: AppSettings) -> String {
        let isDark = settings.appearanceMode == .dark ||
                     (settings.appearanceMode == .system && systemIsDark())

        let backgroundColor = isDark ? "#1e1e1e" : "#ffffff"
        let textColor = isDark ? "#e0e0e0" : "#2c3e50"
        let linkColor = isDark ? "#66b3ff" : "#3498db"
        let codeBackground = isDark ? "#2d2d2d" : "#f5f7fa"
        let codeBorder = isDark ? "#3d3d3d" : "#e1e4e8"
        let blockquoteBackground = isDark ? "#2a2a2a" : "#f9f9fb"
        let blockquoteBorder = isDark ? "#4a4a4a" : "#cbd5e0"
        let hrColor = isDark ? "#3d3d3d" : "#e1e4e8"

        return """
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            background-color: \(backgroundColor);
            color: \(textColor);
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif;
            line-height: 1.7;
            font-size: \(settings.previewFontSize)px;
            transition: background-color 0.3s ease, color 0.3s ease;
        }

        .container {
            max-width: \(settings.maxPreviewWidth)px;
            margin: 0 auto;
            padding: 40px 20px;
        }

        /* Headers */
        h1, h2, h3, h4, h5, h6 {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
            font-weight: 600;
            margin-top: 1.5em;
            margin-bottom: 0.5em;
            line-height: 1.3;
        }

        h1 {
            font-size: 2.2em;
            border-bottom: 2px solid \(hrColor);
            padding-bottom: 0.3em;
        }

        h2 {
            font-size: 1.8em;
            border-bottom: 1px solid \(hrColor);
            padding-bottom: 0.3em;
        }

        h3 { font-size: 1.5em; }
        h4 { font-size: 1.25em; }
        h5 { font-size: 1.1em; }
        h6 { font-size: 1em; opacity: 0.85; }

        /* Paragraphs */
        p {
            margin-bottom: 1em;
            text-align: justify;
        }

        /* Links */
        a {
            color: \(linkColor);
            text-decoration: none;
            border-bottom: 1px solid transparent;
            transition: border-color 0.2s ease;
        }

        a:hover {
            border-bottom-color: \(linkColor);
        }

        /* Code */
        code {
            font-family: "SF Mono", Menlo, Monaco, "Courier New", monospace;
            font-size: 0.9em;
            background-color: \(codeBackground);
            padding: 0.2em 0.4em;
            border-radius: 4px;
            border: 1px solid \(codeBorder);
        }

        pre {
            background-color: \(codeBackground);
            border: 1px solid \(codeBorder);
            border-radius: 8px;
            padding: 16px;
            margin: 1em 0;
            overflow-x: auto;
        }

        pre code {
            background: none;
            border: none;
            padding: 0;
            font-size: 0.95em;
        }

        /* Lists */
        ul, ol {
            margin: 1em 0;
            padding-left: 2em;
        }

        li {
            margin: 0.5em 0;
        }

        /* Blockquotes */
        blockquote {
            background-color: \(blockquoteBackground);
            border-left: 4px solid \(blockquoteBorder);
            padding: 1em 1.5em;
            margin: 1em 0;
            border-radius: 4px;
            font-style: italic;
        }

        blockquote p {
            margin: 0;
        }

        /* Horizontal Rule */
        hr {
            border: none;
            border-top: 2px solid \(hrColor);
            margin: 2em 0;
        }

        /* Images */
        img {
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            margin: 1em 0;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        /* Tables */
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 1em 0;
        }

        th, td {
            border: 1px solid \(codeBorder);
            padding: 0.75em;
            text-align: left;
        }

        th {
            background-color: \(codeBackground);
            font-weight: 600;
        }

        tr:nth-child(even) {
            background-color: \(isDark ? "#252525" : "#f9f9fb");
        }

        /* Smooth scrolling */
        html {
            scroll-behavior: smooth;
        }
        """
    }

    private static func systemIsDark() -> Bool {
        // This is a placeholder - actual implementation would check system appearance
        // In the WebView context, we'll rely on JavaScript or system info
        return false
    }
}
