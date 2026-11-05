//
//  SurfaceTracking.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Follows ledges snow piles on while started, shared by every overlay.
@MainActor
protocol SurfaceTracking: AnyObject {
    /// Starts following the ledges. Does nothing when already started.
    func start()

    /// Stops following the ledges and forgets them.
    func stop()
}
