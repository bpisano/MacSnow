//
//  WindowRecord.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
import Foundation

/// One on-screen window as reported by the window server, in Core Graphics coordinates.
struct WindowRecord: Equatable, Sendable {
    /// The window server's number for the window.
    let number: CGWindowID
    /// The process owning the window.
    let ownerPID: pid_t
    /// The window level, `0` for regular app windows.
    let layer: Int
    /// The window opacity, `0` when fully transparent.
    let alpha: Double
    /// The window frame, origin at the top-left of the primary screen.
    let bounds: CGRect
}

extension WindowRecord {
    /// Reads a record from one `CGWindowListCopyWindowInfo` entry.
    /// - Parameters:
    ///   - info: The entry, keyed by the `kCGWindow…` constants.
    /// - Returns: `nil` when a key is missing or malformed.
    init?(info: [String: Any]) {
        guard
            let number = info[kCGWindowNumber as String] as? NSNumber,
            let ownerPID = info[kCGWindowOwnerPID as String] as? NSNumber,
            let layer = info[kCGWindowLayer as String] as? NSNumber,
            let alpha = info[kCGWindowAlpha as String] as? NSNumber,
            let boundsInfo = info[kCGWindowBounds as String] as? NSDictionary,
            let bounds = CGRect(dictionaryRepresentation: boundsInfo)
        else {
            return nil
        }
        self.init(
            number: number.uint32Value,
            ownerPID: ownerPID.int32Value,
            layer: layer.intValue,
            alpha: alpha.doubleValue,
            bounds: bounds
        )
    }

    /// A record with sensible defaults, any field overridable.
    static func mock(
        number: CGWindowID = 1,
        ownerPID: pid_t = 100,
        layer: Int = 0,
        alpha: Double = 1,
        bounds: CGRect = .init(x: 100, y: 100, width: 800, height: 600)
    ) -> WindowRecord {
        .init(number: number, ownerPID: ownerPID, layer: layer, alpha: alpha, bounds: bounds)
    }
}
