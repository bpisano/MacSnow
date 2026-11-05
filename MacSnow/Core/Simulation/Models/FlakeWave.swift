//
//  FlakeWave.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation

/// One sine swing of a flake's path, its phase set apart per flake by the flake's seed.
struct FlakeWave: Equatable, Sendable {
    /// Swings per radian of the flake's tempo angle.
    let pace: Float
    /// Share of the amplitude it carries.
    let weight: Float
    /// Phase turned per radian of seed.
    let twist: Float
    /// Phase for a zero seed, in radians.
    let offset: Float

    /// The swing's height, from `-weight` to `weight`.
    /// - Parameters:
    ///   - angle: The flake's tempo angle, in radians.
    ///   - seed: The flake's seed, in radians.
    /// - Returns: The weighted sine of the swing's phase.
    func value(at angle: Float, seed: Float) -> Float {
        weight * sin(pace * angle + twist * seed + offset)
    }
}
