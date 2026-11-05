//
//  GrainCatch.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Which drifts catch falling snow.
enum GrainCatch: Equatable, Sendable {
    /// Every drift.
    case anyDrift
    /// Every drift but the one on this ledge: snow thrown off a ledge falls in front of it.
    case anyDriftBut(SnowSurfaceID)
    /// No drift: the snow falls through every ledge, off the screen.
    case noDrift

    /// Whether the drift on `ledge` catches the snow.
    /// - Parameters:
    ///   - ledge: The ledge the snow reaches.
    /// - Returns: `true` when its drift catches the snow.
    func allows(_ ledge: SnowSurfaceID) -> Bool {
        switch self {
        case .anyDrift:
            true
        case let .anyDriftBut(origin):
            ledge != origin
        case .noDrift:
            false
        }
    }
}
