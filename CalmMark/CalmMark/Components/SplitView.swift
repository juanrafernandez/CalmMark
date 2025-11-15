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
    let leading: Leading?
    let center: Center
    let trailing: Trailing?

    @Binding var leadingWidth: CGFloat
    @Binding var trailingWidth: CGFloat

    init(
        leadingWidth: Binding<CGFloat>,
        trailingWidth: Binding<CGFloat>,
        @ViewBuilder leading: () -> Leading?,
        @ViewBuilder center: () -> Center,
        @ViewBuilder trailing: () -> Trailing?
    ) {
        self._leadingWidth = leadingWidth
        self._trailingWidth = trailingWidth
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }

    func makeNSView(context: Context) -> NSSplitView {
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = context.coordinator

        context.coordinator.splitView = splitView
        context.coordinator.updatePanes(leading: leading, center: center, trailing: trailing)

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        context.coordinator.updatePanes(leading: leading, center: center, trailing: trailing)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(leadingWidth: $leadingWidth, trailingWidth: $trailingWidth)
    }

    class Coordinator: NSObject, NSSplitViewDelegate {
        @Binding var leadingWidth: CGFloat
        @Binding var trailingWidth: CGFloat
        var splitView: NSSplitView?
        var leadingController: NSHostingController<AnyView>?
        var centerController: NSHostingController<AnyView>?
        var trailingController: NSHostingController<AnyView>?

        init(leadingWidth: Binding<CGFloat>, trailingWidth: Binding<CGFloat>) {
            self._leadingWidth = leadingWidth
            self._trailingWidth = trailingWidth
        }

        func updatePanes<L: View, C: View, T: View>(leading: L?, center: C, trailing: T?) {
            guard let splitView = splitView else { return }

            // Remove all existing arranged subviews
            splitView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            // Add leading pane if exists
            if let leading = leading {
                if leadingController == nil {
                    leadingController = NSHostingController(rootView: AnyView(leading))
                } else {
                    leadingController?.rootView = AnyView(leading)
                }
                let view = leadingController!.view
                view.translatesAutoresizingMaskIntoConstraints = false
                splitView.addArrangedSubview(view)
            }

            // Add center pane (always exists)
            if centerController == nil {
                centerController = NSHostingController(rootView: AnyView(center))
            } else {
                centerController?.rootView = AnyView(center)
            }
            let centerView = centerController!.view
            centerView.translatesAutoresizingMaskIntoConstraints = false
            centerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            splitView.addArrangedSubview(centerView)

            // Add trailing pane if exists
            if let trailing = trailing {
                if trailingController == nil {
                    trailingController = NSHostingController(rootView: AnyView(trailing))
                } else {
                    trailingController?.rootView = AnyView(trailing)
                }
                let view = trailingController!.view
                view.translatesAutoresizingMaskIntoConstraints = false
                splitView.addArrangedSubview(view)
            }
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
    let bottom: Bottom?

    @Binding var bottomHeight: CGFloat

    init(
        bottomHeight: Binding<CGFloat>,
        @ViewBuilder top: () -> Top,
        @ViewBuilder bottom: () -> Bottom?
    ) {
        self._bottomHeight = bottomHeight
        self.top = top()
        self.bottom = bottom()
    }

    func makeNSView(context: Context) -> NSSplitView {
        let splitView = NSSplitView()
        splitView.isVertical = false  // Vertical = stacks horizontally, so false = stacks vertically
        splitView.dividerStyle = .thin
        splitView.delegate = context.coordinator

        context.coordinator.splitView = splitView
        context.coordinator.updatePanes(top: top, bottom: bottom)

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        context.coordinator.updatePanes(top: top, bottom: bottom)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bottomHeight: $bottomHeight)
    }

    class Coordinator: NSObject, NSSplitViewDelegate {
        @Binding var bottomHeight: CGFloat
        var splitView: NSSplitView?
        var topController: NSHostingController<AnyView>?
        var bottomController: NSHostingController<AnyView>?

        init(bottomHeight: Binding<CGFloat>) {
            self._bottomHeight = bottomHeight
        }

        func updatePanes<T: View, B: View>(top: T, bottom: B?) {
            guard let splitView = splitView else { return }

            // Remove all existing arranged subviews
            splitView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            // Add top pane (always exists)
            if topController == nil {
                topController = NSHostingController(rootView: AnyView(top))
            } else {
                topController?.rootView = AnyView(top)
            }
            let topView = topController!.view
            topView.translatesAutoresizingMaskIntoConstraints = false
            topView.setContentHuggingPriority(.defaultLow, for: .vertical)
            splitView.addArrangedSubview(topView)

            // Add bottom pane if exists
            if let bottom = bottom {
                if bottomController == nil {
                    bottomController = NSHostingController(rootView: AnyView(bottom))
                } else {
                    bottomController?.rootView = AnyView(bottom)
                }
                let bottomView = bottomController!.view
                bottomView.translatesAutoresizingMaskIntoConstraints = false
                splitView.addArrangedSubview(bottomView)
            }
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
