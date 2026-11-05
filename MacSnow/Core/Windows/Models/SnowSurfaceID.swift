//
//  SnowSurfaceID.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics

/// Which ledge a surface is, unique among the ledges on screen.
enum SnowSurfaceID: Hashable, Sendable {
    /// A window top, by the window server's number for the window.
    case window(CGWindowID)
    /// The top of the Dock's tile row.
    case dock
    /// The bottom edge of the screen.
    case ground
}
