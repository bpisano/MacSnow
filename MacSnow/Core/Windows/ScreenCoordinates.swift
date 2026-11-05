//
//  ScreenCoordinates.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics

/// Converts Core Graphics global coordinates (top-left of the primary screen, y down)
/// to Cocoa global coordinates (bottom-left of the primary screen, y up).
struct ScreenCoordinates: Sendable {
    /// The top edge of the primary screen in Cocoa coordinates.
    let primaryScreenMaxY: CGFloat

    /// Converts a frame.
    /// - Parameters:
    ///   - rect: A frame in Core Graphics global coordinates.
    /// - Returns: The same frame in Cocoa global coordinates.
    func cocoaFrame(fromCoreGraphics rect: CGRect) -> CGRect {
        .init(
            x: rect.minX,
            y: primaryScreenMaxY - rect.minY - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}
