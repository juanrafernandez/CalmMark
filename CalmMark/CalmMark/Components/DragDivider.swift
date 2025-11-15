//
//  DragDivider.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//  Draggable divider component for resizable panels (like Xcode)
//

import SwiftUI

/// Draggable divider for resizing panels
struct DragDivider: View {
    let orientation: Orientation
    @Binding var offset: CGFloat
    let minOffset: CGFloat
    let maxOffset: CGFloat
    let invertDirection: Bool  // If true, inverts drag direction (for trailing/bottom panels)

    @State private var isDragging = false
    @State private var dragStartOffset: CGFloat = 0

    enum Orientation {
        case horizontal  // For vertical resizing (top/bottom panels)
        case vertical    // For horizontal resizing (left/right panels)
    }

    // Default initializer with invertDirection = false
    init(
        orientation: Orientation,
        offset: Binding<CGFloat>,
        minOffset: CGFloat,
        maxOffset: CGFloat,
        invertDirection: Bool = false
    ) {
        self.orientation = orientation
        self._offset = offset
        self.minOffset = minOffset
        self.maxOffset = maxOffset
        self.invertDirection = invertDirection
    }

    var body: some View {
        ZStack {
            // Visible divider line
            if orientation == .vertical {
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(width: 1)
            } else {
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(height: 1)
            }

            // Invisible draggable area (wider/taller for easier grabbing)
            Rectangle()
                .fill(Color.clear)
                .frame(
                    width: orientation == .vertical ? 8 : nil,
                    height: orientation == .horizontal ? 8 : nil
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering {
                        if orientation == .vertical {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.resizeUpDown.push()
                        }
                    } else if !isDragging {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                dragStartOffset = offset
                            }

                            let translation = orientation == .vertical ? value.translation.width : value.translation.height
                            // Invert direction for trailing/bottom panels
                            let adjustedTranslation = invertDirection ? -translation : translation
                            var newOffset = dragStartOffset + adjustedTranslation

                            // Clamp to min/max
                            newOffset = max(minOffset, min(maxOffset, newOffset))

                            // Update immediately without animation for smooth dragging
                            withAnimation(.none) {
                                offset = newOffset
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            NSCursor.pop()
                        }
                )
        }
        .frame(
            width: orientation == .vertical ? 8 : nil,
            height: orientation == .horizontal ? 8 : nil
        )
    }
}

// MARK: - Preview

struct DragDivider_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 0) {
            Color.blue
                .frame(width: 200)

            DragDivider(
                orientation: .vertical,
                offset: .constant(200),
                minOffset: 150,
                maxOffset: 400
            )

            Color.green
        }
        .frame(height: 300)
    }
}
