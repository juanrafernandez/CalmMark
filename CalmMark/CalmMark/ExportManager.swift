//
//  ExportManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import AppKit
import WebKit

enum ExportType {
    case html
    case pdf
}

class ExportManager {

    static func exportHTML(markdown: String, settings: AppSettings, to url: URL) -> Bool {
        let html = MarkdownRenderer.renderToHTML(markdown, settings: settings)

        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Error exporting HTML: \(error)")
            return false
        }
    }

    static func exportPDF(markdown: String, settings: AppSettings, to url: URL, completion: @escaping (Bool) -> Void) {
        let html = MarkdownRenderer.renderToHTML(markdown, settings: settings)

        // Create a temporary WebView for PDF generation
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 1000))

        webView.loadHTMLString(html, baseURL: nil)

        // Wait for load to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let config = WKPDFConfiguration()
            config.rect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size

            webView.createPDF(configuration: config) { result in
                switch result {
                case .success(let data):
                    do {
                        try data.write(to: url)
                        completion(true)
                    } catch {
                        print("Error writing PDF: \(error)")
                        completion(false)
                    }
                case .failure(let error):
                    print("Error creating PDF: \(error)")
                    completion(false)
                }
            }
        }
    }

    static func suggestedFileName(for type: ExportType) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let dateString = dateFormatter.string(from: Date())

        switch type {
        case .html:
            return "CalmMark-Export-\(dateString).html"
        case .pdf:
            return "CalmMark-Export-\(dateString).pdf"
        }
    }
}
