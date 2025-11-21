//
//  SplashScreenView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-21.
//  Splash screen with animation while app initializes
//

import SwiftUI

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            // Animated logo
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.green.opacity(0.3),
                                Color.mint.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(scale)
                    .opacity(opacity)

                // Main icon
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotationAngle))
            }

            // App name
            VStack(spacing: 8) {
                Text("CalmMark")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .opacity(opacity)

                Text("Loading...")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .opacity(opacity * 0.8)
            }

            // Loading indicator
            ProgressView()
                .scaleEffect(1.2)
                .opacity(opacity)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
        .onAppear {
            // Animate logo entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Gentle rotation animation
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
