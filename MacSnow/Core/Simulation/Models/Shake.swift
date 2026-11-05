//
//  Shake.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Snow about to be thrown off a drift by its window's motion.
struct Shake: Equatable, Sendable {
    /// Snow thrown, as a share of a full drift.
    let share: Float
    /// Speed given to the thrown snow, in points per second. It flies the way its horizontal speed points.
    let impulse: SIMD2<Float>
}
