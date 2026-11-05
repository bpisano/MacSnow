//
//  OverlayFactory.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Makes the overlays shown while snow is falling, one per screen.
@MainActor
protocol OverlayFactory {
    /// Makes an overlay covering `screen`, off screen until shown.
    /// - Parameters:
    ///   - screen: The screen to cover.
    /// - Returns: The overlay.
    func makeOverlay(covering screen: SnowScreen) -> any Overlay
}
