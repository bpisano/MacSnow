//
//  DockReader.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics

/// A source of the Dock's geometry.
protocol DockReader {
    /// Reads where the Dock's tile row is, shown or not.
    /// - Returns: The tile row frame in Core Graphics global coordinates, `nil` when it can't be read.
    func tileRowFrame() -> CGRect?
}
