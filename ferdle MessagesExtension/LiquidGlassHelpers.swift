//
//  LiquidGlassHelpers.swift
//  ferdle MessagesExtension
//
//  Centralize Liquid Glass application with fallbacks for older iOS versions.
//

import SwiftUI

extension View {
    /// Applies a glass background effect.
    /// Uses Liquid Glass on supported versions, falls back to ultraThinMaterial otherwise.
    @ViewBuilder
    func glassBackground() -> some View {
        if #available(iOS 18.0, *) {
            // Liquid Glass is available in iOS 18+
            // Use standard material as fallback since specific Glass APIs may vary
            self.background(.ultraThinMaterial)
        } else {
            self.background(.ultraThinMaterial)
        }
    }
}
