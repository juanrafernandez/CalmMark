//
//  SplitView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//  Native NSSplitView wrapper for Xcode-level smooth resizing
//

import SwiftUI
import AppKit

/// Wrapper for NSSplitView to provide native AppKit split view functionality in SwiftUI
/// This provides the same smooth, hardware-accelerated resizing as Xcode
struct SplitView<Content: View>: NSViewRepresentable {
    let isVertical: Bool
    let content: Content

    @Binding var dividerPositions: [CGFloat]

    init(
        isVertical: Bool = false,
        dividerPositions: Binding<[CGFloat]> = .constant([]),
        @ViewBuilder content: () -> Content
    ) {
        self.isVertical = isVertical
        self._dividerPositions = dividerPositions
        self.content = content()
    }

    func makeNSView(context: Context) -> NSSplitView {
        let splitView = NSSplitView()
        splitView.isVertical = isVertical
        splitView.dividerStyle = .thin
        splitView.delegate = context.coordinator

        // Extract child views from SwiftUI content
        let hostingController = NSHostingController(rootView: content)

        // Add the hosting view as a subview
        splitView.addArrangedSubview(hostingController.view)

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        // Update split view properties if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(dividerPositions: $dividerPositions)
    }

    class Coordinator: NSObject, NSSplitViewDelegate {
        @Binding var dividerPositions: [CGFloat]

        init(dividerPositions: Binding<[CGFloat]>) {
            self._dividerPositions = dividerPositions
        }

        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            // Set minimum size constraints
            switch dividerIndex {
            case 0: return 150  // Sidebar minimum
            default: return 200
            }
        }

        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            // Set maximum size constraints
            let totalSize = splitView.isVertical ? splitView.bounds.width : splitView.bounds.height
            switch dividerIndex {
            case 0: return min(500, totalSize * 0.4)  // Sidebar maximum
            default: return totalSize - 200
            }
        }

        func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
            // Middle pane (editor) should resize when window resizes
            if let index = splitView.arrangedSubviews.firstIndex(of: view) {
                return index == 1  // Editor is always in middle
            }
            return false
        }

        func splitViewDidResizeSubviews(_ notification: Notification) {
            // Save divider positions when user drags
            guard let splitView = notification.object as? NSSplitView else { return }

            var positions: [CGFloat] = []
            for i in 0..<splitView.arrangedSubviews.count - 1 {
                let frame = splitView.arrangedSubviews[i].frame
                let position = splitView.isVertical ? frame.width : frame.height
                positions.append(position)
            }

            DispatchQueue.main.async {
                self.dividerPositions = positions
            }
        }
    }
}

/// Three-pane horizontal split view (sidebar, editor, preview)
struct HSplitView3<Leading: View, Center: View, Trailing: View>: NSViewRepresentable {
    let leading: Leading
    let center: Center
    let trailing: Trailing

    let showLeading: Bool
    let showTrailing: Bool

    @Binding var leadingWidth: CGFloat
    @Binding var trailingWidth: CGFloat

    init(
        leadingWidth: Binding<CGFloat>,
        trailingWidth: Binding<CGFloat>,
        showLeading: Bool = true,
        showTrailing: Bool = true,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder center: () -> Center,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self._leadingWidth = leadingWidth
        self._trailingWidth = trailingWidth
        self.showLeading = showLeading
        self.showTrailing = showTrailing
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }

    func makeNSView(context: Context) -> NSSplitView {
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = context.coordinator

        // Create all three panes (always)
        let leadingController = NSHostingController(rootView: leading)
        let centerController = NSHostingController(rootView: center)
        let trailingController = NSHostingController(rootView: trailing)

        context.coordinator.leadingController = leadingController
        context.coordinator.centerController = centerController
        context.coordinator.trailingController = trailingController

        leadingController.view.translatesAutoresizingMaskIntoConstraints = false
        centerController.view.translatesAutoresizingMaskIntoConstraints = false
        centerController.view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        trailingController.view.translatesAutoresizingMaskIntoConstraints = false

        splitView.addArrangedSubview(leadingController.view)
        splitView.addArrangedSubview(centerController.view)
        splitView.addArrangedSubview(trailingController.view)

        // Apply initial visibility
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(251), forSubviewAt: 0)
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(251), forSubviewAt: 2)

        if !showLeading {
            leadingController.view.isHidden = true
        }
        if !showTrailing {
            trailingController.view.isHidden = true
        }

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        // Update visibility of panels
        guard splitView.arrangedSubviews.count == 3 else { return }

        splitView.arrangedSubviews[0].isHidden = !showLeading
        splitView.arrangedSubviews[2].isHidden = !showTrailing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(leadingWidth: $leadingWidth, trailingWidth: $trailingWidth)
    }

    class Coordinator: NSObject, NSSplitViewDelegate {
        @Binding var leadingWidth: CGFloat
        @Binding var trailingWidth: CGFloat
        var leadingController: NSHostingController<Leading>?
        var centerController: NSHostingController<Center>?
        var trailingController: NSHostingController<Trailing>?

        init(leadingWidth: Binding<CGFloat>, trailingWidth: Binding<CGFloat>) {
            self._leadingWidth = leadingWidth
            self._trailingWidth = trailingWidth
        }

        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            switch dividerIndex {
            case 0: return 150   // Sidebar minimum
            default: return 200  // Preview minimum
            }
        }

        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            let totalWidth = splitView.bounds.width
            switch dividerIndex {
            case 0: return min(500, totalWidth * 0.4)  // Sidebar maximum
            default: return totalWidth - 200           // Preview minimum space
            }
        }

        func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
            // Center pane (editor) should resize when window resizes
            guard let index = splitView.arrangedSubviews.firstIndex(of: view) else { return false }
            return index == 1  // Editor is in the middle
        }

        func splitViewDidResizeSubviews(_ notification: Notification) {
            // NSSplitView handles all resizing internally
            // We don't need to sync back to SwiftUI state during dragging
            // This prevents "Modifying state during view update" warnings
        }
    }
}

/// Vertical split view for top/bottom panels (main content / debug panel)
struct VSplitView2<Top: View, Bottom: View>: NSViewRepresentable {
    let top: Top
    let bottom: Bottom

    let showBottom: Bool

    @Binding var bottomHeight: CGFloat

    init(
        bottomHeight: Binding<CGFloat>,
        showBottom: Bool = true,
        @ViewBuilder top: () -> Top,
        @ViewBuilder bottom: () -> Bottom
    ) {
        self._bottomHeight = bottomHeight
        self.showBottom = showBottom
        self.top = top()
        self.bottom = bottom()
    }

    func makeNSView(context: Context) -> NSSplitView {
        let splitView = NSSplitView()
        splitView.isVertical = false  // Vertical = stacks horizontally, so false = stacks vertically
        splitView.dividerStyle = .thin
        splitView.delegate = context.coordinator

        // Create both panes (always)
        let topController = NSHostingController(rootView: top)
        let bottomController = NSHostingController(rootView: bottom)

        context.coordinator.topController = topController
        context.coordinator.bottomController = bottomController

        topController.view.translatesAutoresizingMaskIntoConstraints = false
        topController.view.setContentHuggingPriority(.defaultLow, for: .vertical)
        bottomController.view.translatesAutoresizingMaskIntoConstraints = false

        splitView.addArrangedSubview(topController.view)
        splitView.addArrangedSubview(bottomController.view)

        // Apply initial visibility
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(251), forSubviewAt: 1)

        if !showBottom {
            bottomController.view.isHidden = true
        }

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        // Update visibility of bottom panel
        guard splitView.arrangedSubviews.count == 2 else { return }

        splitView.arrangedSubviews[1].isHidden = !showBottom
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bottomHeight: $bottomHeight)
    }

    class Coordinator: NSObject, NSSplitViewDelegate {
        @Binding var bottomHeight: CGFloat
        var topController: NSHostingController<Top>?
        var bottomController: NSHostingController<Bottom>?

        init(bottomHeight: Binding<CGFloat>) {
            self._bottomHeight = bottomHeight
        }

        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            let totalHeight = splitView.bounds.height
            return totalHeight - 600  // Bottom panel maximum (600px)
        }

        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            let totalHeight = splitView.bounds.height
            return totalHeight - 100  // Bottom panel minimum (100px)
        }

        func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
            // Top pane should resize when window resizes
            guard let index = splitView.arrangedSubviews.firstIndex(of: view) else { return false }
            return index == 0
        }

        func splitViewDidResizeSubviews(_ notification: Notification) {
            // NSSplitView handles all resizing internally
            // We don't need to sync back to SwiftUI state during dragging
            // This prevents "Modifying state during view update" warnings
        }
    }
}
