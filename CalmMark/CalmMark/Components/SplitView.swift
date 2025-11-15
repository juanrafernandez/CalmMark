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

        // Add leading pane if exists
        if let leading = leading {
            let hostingView = NSHostingController(rootView: leading).view
            hostingView.widthAnchor.constraint(greaterThanOrEqualToConstant: leadingWidth).isActive = true
            splitView.addArrangedSubview(hostingView)
        }

        // Add center pane (always exists)
        let centerView = NSHostingController(rootView: center).view
        centerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        splitView.addArrangedSubview(centerView)

        // Add trailing pane if exists
        if let trailing = trailing {
            let hostingView = NSHostingController(rootView: trailing).view
            hostingView.widthAnchor.constraint(greaterThanOrEqualToConstant: trailingWidth).isActive = true
            splitView.addArrangedSubview(hostingView)
        }

        // Set initial positions
        splitView.setPosition(leadingWidth, ofDividerAt: 0)
        if trailing != nil && splitView.arrangedSubviews.count > 2 {
            let totalWidth = splitView.bounds.width
            splitView.setPosition(totalWidth - trailingWidth, ofDividerAt: splitView.arrangedSubviews.count - 2)
        }

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        // Handle view updates (show/hide panels)
        context.coordinator.leadingWidth = leadingWidth
        context.coordinator.trailingWidth = trailingWidth
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(leadingWidth: $leadingWidth, trailingWidth: $trailingWidth)
    }

    class Coordinator: NSObject, NSSplitViewDelegate {
        @Binding var leadingWidth: CGFloat
        @Binding var trailingWidth: CGFloat

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
            guard let splitView = notification.object as? NSSplitView else { return }

            // Update leading width
            if splitView.arrangedSubviews.count > 0 {
                let newLeadingWidth = splitView.arrangedSubviews[0].frame.width
                if abs(newLeadingWidth - leadingWidth) > 1 {
                    DispatchQueue.main.async {
                        self.leadingWidth = newLeadingWidth
                    }
                }
            }

            // Update trailing width
            if splitView.arrangedSubviews.count > 2 {
                let newTrailingWidth = splitView.arrangedSubviews.last!.frame.width
                if abs(newTrailingWidth - trailingWidth) > 1 {
                    DispatchQueue.main.async {
                        self.trailingWidth = newTrailingWidth
                    }
                }
            }
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

        // Add top pane
        let topView = NSHostingController(rootView: top).view
        topView.setContentHuggingPriority(.defaultLow, for: .vertical)
        splitView.addArrangedSubview(topView)

        // Add bottom pane if exists
        if let bottom = bottom {
            let bottomView = NSHostingController(rootView: bottom).view
            bottomView.heightAnchor.constraint(greaterThanOrEqualToConstant: bottomHeight).isActive = true
            splitView.addArrangedSubview(bottomView)

            // Set initial position
            let totalHeight = splitView.bounds.height
            splitView.setPosition(totalHeight - bottomHeight, ofDividerAt: 0)
        }

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        context.coordinator.bottomHeight = bottomHeight

        // Handle showing/hiding bottom panel
        if bottom == nil && splitView.arrangedSubviews.count > 1 {
            splitView.arrangedSubviews.last?.removeFromSuperview()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bottomHeight: $bottomHeight)
    }

    class Coordinator: NSObject, NSSplitViewDelegate {
        @Binding var bottomHeight: CGFloat

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
            guard let splitView = notification.object as? NSSplitView else { return }

            if splitView.arrangedSubviews.count > 1 {
                let newBottomHeight = splitView.arrangedSubviews.last!.frame.height
                if abs(newBottomHeight - bottomHeight) > 1 {
                    DispatchQueue.main.async {
                        self.bottomHeight = newBottomHeight
                    }
                }
            }
        }
    }
}
