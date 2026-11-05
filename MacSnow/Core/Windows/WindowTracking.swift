//
//  WindowTracking.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Reports the window tops snow piles on.
@MainActor
protocol WindowTracking: AnyObject {
    /// The window tops of every screen, front to back, in Cocoa global coordinates.
    var surfaces: [SnowSurface] { get }
}
