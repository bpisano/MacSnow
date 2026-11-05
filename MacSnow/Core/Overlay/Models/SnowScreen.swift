//
//  SnowScreen.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics

/// A screen snow falls on: one overlay covers each.
struct SnowScreen: Hashable, Sendable {
    /// The display showing the screen.
    let id: CGDirectDisplayID
    /// The screen frame in Cocoa global coordinates, origin at the bottom-left of the primary screen.
    let frame: CGRect
    /// The pixels per point.
    let scale: CGFloat

    /// Hashes every field, as equality compares them all.
    /// - Parameters:
    ///   - hasher: The hasher to feed.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(frame.origin.x)
        hasher.combine(frame.origin.y)
        hasher.combine(frame.size.width)
        hasher.combine(frame.size.height)
        hasher.combine(scale)
    }
}

extension SnowScreen {
    /// A screen with sensible defaults, any field overridable.
    static func mock(
        id: CGDirectDisplayID = 1,
        frame: CGRect = .init(x: 0, y: 0, width: 1440, height: 900),
        scale: CGFloat = 2
    ) -> SnowScreen {
        .init(id: id, frame: frame, scale: scale)
    }
}
