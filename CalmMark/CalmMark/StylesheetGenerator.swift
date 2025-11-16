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
            margin-top: 24px;
            margin-bottom: 16px;
            line-height: 1.25;
        }

        h1 {
            font-size: 2em;
            border-bottom: 1px solid \(hrColor);
            padding-bottom: 0.3em;
            margin-top: 0;
            margin-bottom: 16px;
        }

        h2 {
            font-size: 1.5em;
            border-bottom: 1px solid \(hrColor);
            padding-bottom: 0.3em;
        }

        h3 { font-size: 1.25em; }
        h4 { font-size: 1em; }
        h5 { font-size: 0.875em; }
        h6 { font-size: 0.85em; color: \(isDark ? "#8b949e" : "#57606a"); }

        /* Paragraphs */
        p {
            margin-top: 0;
            margin-bottom: 16px;
            text-align: left;
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
            font-size: 85%;
            background-color: \(codeBackground);
            padding: 0.2em 0.4em;
            border-radius: 6px;
        }

        pre {
            background-color: \(codeBackground);
            border-radius: 6px;
            padding: 16px;
            margin-top: 0;
            margin-bottom: 16px;
            overflow-x: auto;
            line-height: 1.45;
            white-space: pre;
            overflow-wrap: normal;
            font-family: "SF Mono", Menlo, Monaco, "Courier New", monospace;
        }

        pre code {
            background: none;
            border: none;
            padding: 0;
            font-size: 100%;
            display: block;
            overflow: visible;
            line-height: inherit;
            white-space: pre;
        }

        /* Lists */
        ul, ol {
            margin-top: 0;
            margin-bottom: 16px;
            padding-left: 2em;
        }

        li {
            margin-top: 0.25em;
        }

        li + li {
            margin-top: 0.25em;
        }

        /* Task lists */
        ul.task-list {
            list-style-type: none;
            padding-left: 0;
        }

        .task-list-item {
            list-style-type: none;
        }

        .task-list-item input[type="checkbox"] {
            margin: 0 0.5em 0.25em -1.6em;
            vertical-align: middle;
        }

        /* Blockquotes */
        blockquote {
            background-color: \(blockquoteBackground);
            border-left: 0.25em solid \(blockquoteBorder);
            padding: 0 1em;
            margin-left: 0;
            margin-right: 0;
            margin-top: 0;
            margin-bottom: 16px;
        }

        blockquote > :first-child {
            margin-top: 0;
        }

        blockquote > :last-child {
            margin-bottom: 0;
        }

        /* Horizontal Rule */
        hr {
            height: 0.25em;
            padding: 0;
            margin: 24px 0;
            background-color: \(hrColor);
            border: 0;
        }

        /* Images */
        img {
            max-width: 100%;
            height: auto;
            vertical-align: middle;
            /* Inline by default for badges */
            display: inline-block;
            margin: 0.2em 0.3em;
        }

        /* Large images get more spacing */
        img[src*=".png"],
        img[src*=".jpg"],
        img[src*=".jpeg"],
        img[src*=".gif"]:not([src*="shields.io"]):not([src*="badge"]) {
            display: block;
            margin: 1em auto;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        /* Badges and shields stay inline */
        img[src*="shields.io"],
        img[src*="badge"],
        img[src*=".svg"] {
            display: inline-block;
            margin: 0.2em 0.3em;
            vertical-align: middle;
            border-radius: 3px;
            box-shadow: none;
        }

        /* Tables */
        table {
            border-spacing: 0;
            border-collapse: collapse;
            display: block;
            margin-top: 0;
            margin-bottom: 16px;
            width: max-content;
            max-width: 100%;
            overflow: auto;
        }

        th, td {
            padding: 6px 13px;
            border: 1px solid \(codeBorder);
        }

        th {
            font-weight: 600;
            background-color: \(isDark ? "#161b22" : "#f6f8fa");
        }

        tr {
            background-color: \(backgroundColor);
            border-top: 1px solid \(codeBorder);
        }

        tr:nth-child(2n) {
            background-color: \(isDark ? "#0d1117" : "#f6f8fa");
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
