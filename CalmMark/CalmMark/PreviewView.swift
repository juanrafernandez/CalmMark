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
    @State private var webView: WKWebView?
    @State private var updateTask: DispatchWorkItem?

    var body: some View {
        WebViewWrapper(html: $html, webView: $webView)
            .onChange(of: markdown) { oldValue, newValue in
                debouncedUpdate(newValue)
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

    // Debounce para evitar actualizaciones muy frecuentes
    private func debouncedUpdate(_ markdown: String) {
        updateTask?.cancel()

        let task = DispatchWorkItem { [markdown] in
            updateHTML(markdown)
        }

        updateTask = task

        // Actualizar después de 150ms de inactividad
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: task)
    }

    private func updateHTML(_ markdown: String) {
        LogManager.shared.log(.debug, "Iniciando renderizado de markdown (\(markdown.count) caracteres)", context: "Preview")

        let newHTML = MarkdownRenderer.renderToHTML(markdown, settings: settings)
        html = newHTML

        LogManager.shared.log(.debug, "HTML generado (\(newHTML.count) caracteres)", context: "Preview")

        // Force reload if webView is already created
        DispatchQueue.main.async {
            if let webView = webView {
                LogManager.shared.log(.info, "Cargando HTML en WebView", context: "Preview")
                webView.loadHTMLString(newHTML, baseURL: nil)
            } else {
                LogManager.shared.log(.warning, "WebView aún no está inicializado", context: "Preview")
            }
        }
    }
}

struct WebViewWrapper: NSViewRepresentable {
    @Binding var html: String
    @Binding var webView: WKWebView?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        // Enable JavaScript (for potential future enhancements)
        config.preferences.javaScriptEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Configure appearance
        webView.setValue(false, forKey: "drawsBackground")

        // Allow magnification
        webView.allowsMagnification = true

        // Store reference
        DispatchQueue.main.async {
            self.webView = webView
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only reload if content actually changed and webView is not loading
        guard !html.isEmpty else { return }

        if webView.isLoading {
            webView.stopLoading()
        }

        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            LogManager.shared.log(.success, "Preview cargado exitosamente", context: "WebView")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            LogManager.shared.log(.error, "Error al cargar preview: \(error.localizedDescription)", context: "WebView")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            LogManager.shared.log(.error, "Error provisional al cargar preview: \(error.localizedDescription)", context: "WebView")
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            LogManager.shared.log(.debug, "Iniciando carga de preview", context: "WebView")
        }
    }
}

