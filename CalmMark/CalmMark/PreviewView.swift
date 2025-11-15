//
//  PreviewView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import WebKit

struct PreviewView: View {
    let markdown: String
    @ObservedObject var settings: AppSettings
    @State private var html: String = ""

    var body: some View {
        WebView(html: html)
            .onChange(of: markdown) { oldValue, newValue in
                updateHTML(newValue)
            }
            .onChange(of: settings.appearanceMode) { _, _ in
                updateHTML(markdown)
            }
            .onChange(of: settings.previewFontSize) { _, _ in
                updateHTML(markdown)
            }
            .onChange(of: settings.maxPreviewWidth) { _, _ in
                updateHTML(markdown)
            }
            .onAppear {
                updateHTML(markdown)
            }
    }

    private func updateHTML(_ markdown: String) {
        html = MarkdownRenderer.renderToHTML(markdown, settings: settings)
    }
}

struct WebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // Transparent background

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only reload if content actually changed
        if webView.isLoading {
            webView.stopLoading()
        }

        webView.loadHTMLString(html, baseURL: nil)
    }
}
