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

    // CRITICAL: This key changes when content changes, forcing updateNSView to be called
    let contentKey: String

    @Binding var leadingWidth: CGFloat
    @Binding var trailingWidth: CGFloat

    init(
        leadingWidth: Binding<CGFloat>,
        trailingWidth: Binding<CGFloat>,
        showLeading: Bool = true,
        showTrailing: Bool = true,
        contentKey: String = "",
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder center: () -> Center,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self._leadingWidth = leadingWidth
        self._trailingWidth = trailingWidth
        self.showLeading = showLeading
        self.showTrailing = showTrailing
        self.contentKey = contentKey
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }

    func makeNSView(context: Context) -> NSSplitView {
        print("🔧 [HSplitView3] Creating split view - showLeading: \(showLeading), showTrailing: \(showTrailing)")

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

        print("📊 [HSplitView3] Added \(splitView.arrangedSubviews.count) subviews to split view")

        // IMPORTANTE: Establecer isHidden INMEDIATAMENTE para evitar race conditions
        if !showLeading {
            leadingController.view.isHidden = true
            print("👁️ [HSplitView3] Set leading panel hidden=true initially")
        }
        if !showTrailing {
            trailingController.view.isHidden = true
            print("👁️ [HSplitView3] Set trailing panel hidden=true initially")
        }

        // IMPORTANTE: Establecer posiciones de divisores DESPUÉS de que el split view tenga bounds válidos
        DispatchQueue.main.async {
            if self.showLeading {
                splitView.setPosition(self.leadingWidth, ofDividerAt: 0)
                print("📐 [HSplitView3] Set leading panel position to \(self.leadingWidth)")
            } else {
                splitView.setPosition(0, ofDividerAt: 0)
                print("📐 [HSplitView3] Collapsed leading divider to 0")
            }

            if self.showTrailing {
                let totalWidth = splitView.bounds.width
                splitView.setPosition(totalWidth - self.trailingWidth, ofDividerAt: 1)
                print("📐 [HSplitView3] Set trailing panel position to \(totalWidth - self.trailingWidth)")
            } else {
                let totalWidth = splitView.bounds.width
                splitView.setPosition(totalWidth, ofDividerAt: 1)
                print("📐 [HSplitView3] Collapsed trailing divider to \(totalWidth)")
            }
        }

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        // Update visibility of panels using NSSplitView's native collapse/expand
        guard splitView.arrangedSubviews.count == 3 else { return }

        print("🔄 [HSplitView3] updateNSView - showLeading: \(showLeading), showTrailing: \(showTrailing), contentKey: \(contentKey)")

        // CRITICAL: Update the content of hosting controllers
        // This ensures that when activeFile changes, the center panel updates to show EditorView
        if let leadingController = context.coordinator.leadingController {
            leadingController.rootView = leading
        }
        if let centerController = context.coordinator.centerController {
            centerController.rootView = center
            print("📝 [HSplitView3] Updated center panel content")
        }
        if let trailingController = context.coordinator.trailingController {
            trailingController.rootView = trailing
        }

        // Leading panel (sidebar)
        let leadingView = splitView.arrangedSubviews[0]
        let shouldCollapseLeading = !showLeading
        if shouldCollapseLeading != leadingView.isHidden {
            print("🔄 [HSplitView3] Leading panel state change: hidden=\(leadingView.isHidden) -> \(shouldCollapseLeading)")
            if shouldCollapseLeading {
                leadingView.isHidden = true
                splitView.setPosition(0, ofDividerAt: 0)
                print("👁️ [HSplitView3] Collapsing leading panel")
            } else {
                leadingView.isHidden = false
                splitView.setPosition(leadingWidth, ofDividerAt: 0)
                print("👁️ [HSplitView3] Expanding leading panel to \(leadingWidth)")
            }
        }

        // Trailing panel (preview)
        let trailingView = splitView.arrangedSubviews[2]
        let shouldCollapseTrailing = !showTrailing
        print("🔍 [HSplitView3] Trailing panel - shouldCollapse: \(shouldCollapseTrailing), isHidden: \(trailingView.isHidden)")

        // CRITICAL: Always set isHidden and position based on showTrailing
        // Not just when there's a state change, because rootView updates can reset isHidden
        if shouldCollapseTrailing {
            if !trailingView.isHidden {
                print("🔄 [HSplitView3] Trailing panel state change: hidden=\(trailingView.isHidden) -> true")
            }
            trailingView.isHidden = true
            let totalWidth = splitView.bounds.width
            splitView.setPosition(totalWidth, ofDividerAt: 1)
            print("👁️ [HSplitView3] Collapsing trailing panel (totalWidth: \(totalWidth))")
        } else {
            if trailingView.isHidden {
                print("🔄 [HSplitView3] Trailing panel state change: hidden=\(trailingView.isHidden) -> false")
            }
            trailingView.isHidden = false
            let totalWidth = splitView.bounds.width
            let position = totalWidth - trailingWidth
            splitView.setPosition(position, ofDividerAt: 1)
            print("👁️ [HSplitView3] Expanding trailing panel - totalWidth:\(totalWidth), trailingWidth:\(trailingWidth), position:\(position)")
        }
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

    // CRITICAL: This triggers updateNSView when content changes, without destroying the view
    let contentVersion: Int

    @Binding var bottomHeight: CGFloat

    init(
        bottomHeight: Binding<CGFloat>,
        showBottom: Bool = true,
        contentVersion: Int = 0,
        @ViewBuilder top: () -> Top,
        @ViewBuilder bottom: () -> Bottom
    ) {
        self._bottomHeight = bottomHeight
        self.showBottom = showBottom
        self.contentVersion = contentVersion
        self.top = top()
        self.bottom = bottom()
    }

    func makeNSView(context: Context) -> NSSplitView {
        print("🔧 [VSplitView2] Creating split view - showBottom: \(showBottom)")

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

        print("📊 [VSplitView2] Added \(splitView.arrangedSubviews.count) subviews to split view")

        // IMPORTANTE: Establecer posiciones iniciales DESPUÉS de agregar las vistas
        DispatchQueue.main.async {
            if self.showBottom {
                let totalHeight = splitView.bounds.height
                splitView.setPosition(totalHeight - self.bottomHeight, ofDividerAt: 0)
                print("📐 [VSplitView2] Set bottom panel position to \(totalHeight - self.bottomHeight)")
            } else {
                let totalHeight = splitView.bounds.height
                splitView.setPosition(totalHeight, ofDividerAt: 0)
                bottomController.view.isHidden = true
                print("👁️ [VSplitView2] Collapsed bottom panel")
            }
        }

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        // Update visibility of bottom panel using NSSplitView's native collapse/expand
        guard splitView.arrangedSubviews.count == 2 else { return }

        print("🔄 [VSplitView2] updateNSView - showBottom: \(showBottom), contentVersion: \(contentVersion)")

        // CRITICAL: Update the content of hosting controllers
        // This updates the content WITHOUT destroying and recreating the views
        if let topController = context.coordinator.topController {
            topController.rootView = top
            print("📝 [VSplitView2] Updated top panel content (version \(contentVersion))")
        }
        if let bottomController = context.coordinator.bottomController {
            bottomController.rootView = bottom
        }

        let bottomView = splitView.arrangedSubviews[1]
        let shouldCollapseBottom = !showBottom
        if shouldCollapseBottom != bottomView.isHidden {
            if shouldCollapseBottom {
                bottomView.isHidden = true
                let totalHeight = splitView.bounds.height
                splitView.setPosition(totalHeight, ofDividerAt: 0)
            } else {
                bottomView.isHidden = false
                let totalHeight = splitView.bounds.height
                splitView.setPosition(totalHeight - bottomHeight, ofDividerAt: 0)
            }
        }
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
