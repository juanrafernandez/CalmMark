//
//  ScrollSyncManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-17.
//

import Foundation
import Combine

enum ScrollSource {
    case editor
    case preview
    case none
}

class ScrollSyncManager: ObservableObject {
    static let shared = ScrollSyncManager()

    @Published var scrollPercentage: Double = 0.0
    @Published var currentLine: Int = 1
    @Published var totalLines: Int = 1
    @Published var lastScrollSource: ScrollSource = .none
    @Published var isEnabled: Bool = true

    private init() {}

    func updateScroll(percentage: Double, line: Int, total: Int, source: ScrollSource) {
        guard isEnabled else { return }

        // Avoid infinite loops - only update if coming from a different source
        let lineChanged = (currentLine != line || totalLines != total)
        let percentageChanged = abs(scrollPercentage - percentage) > 0.001

        guard source != lastScrollSource || lineChanged || percentageChanged else {
            return
        }

        scrollPercentage = percentage
        currentLine = line
        totalLines = total
        lastScrollSource = source
    }

    func toggleSync() {
        isEnabled.toggle()
    }
}
