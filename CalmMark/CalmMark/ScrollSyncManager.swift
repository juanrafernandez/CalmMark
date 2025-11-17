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
    @Published var lastScrollSource: ScrollSource = .none
    @Published var isEnabled: Bool = true
    @Published var isUserScrolling: Bool = false

    private var userScrollTimer: Timer?

    private init() {}

    func updateScroll(percentage: Double, source: ScrollSource) {
        guard isEnabled else { return }

        // Avoid infinite loops - only update if coming from a different source
        guard source != lastScrollSource || abs(scrollPercentage - percentage) > 0.001 else {
            return
        }

        scrollPercentage = percentage
        lastScrollSource = source

        // Mark that user is scrolling and reset timer
        markUserScrolling()
    }

    private func markUserScrolling() {
        isUserScrolling = true

        // Cancel existing timer
        userScrollTimer?.invalidate()

        // Set a timer to reset the flag after user stops scrolling
        userScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.isUserScrolling = false
        }
    }

    func toggleSync() {
        isEnabled.toggle()
    }
}
