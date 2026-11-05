//
//  DockWatching.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics

/// Reports the Dock's tile row snow piles on.
@MainActor
protocol DockWatching: AnyObject {
    /// The Dock's tile row in Cocoa global coordinates, `nil` when it catches no snow.
    var tileRow: CGRect? { get }
}
