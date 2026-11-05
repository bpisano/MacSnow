//
//  Grain.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation

/// A clump of snow falling off a drift, in points with the origin at the bottom left of the screen.
///
/// Falls under gravity, slowed by the air, until a drift catches it and piles its snow,
/// or off the screen when it falls through every ledge.
/// Snow knocked off a ledge falls in front of it: that ledge's drift never catches it.
struct Grain: Equatable, Sendable {
    /// Downward pull, in points per second squared.
    static let gravity: Float = 900
    /// Rate at which the air slows it, per second.
    static let drag: Float = 1.2

    /// Center.
    let position: SIMD2<Float>
    /// Speed, in points per second.
    let velocity: SIMD2<Float>
    /// Snow area it carries, in square points.
    let area: Float
    /// Diameter, in points: as wide as a flake carrying the same snow.
    let size: Float
    /// Turn of its irregular outline, in radians.
    let turn: Float
    /// Which drifts catch it.
    let catching: GrainCatch

    /// Creates a clump carrying `area` of snow.
    /// - Parameters:
    ///   - position: Center.
    ///   - velocity: Speed, in points per second.
    ///   - area: Snow area it carries, in square points.
    ///   - turn: Turn of its irregular outline, in radians.
    ///   - catching: Which drifts catch it.
    init(
        position: SIMD2<Float>,
        velocity: SIMD2<Float>,
        area: Float,
        turn: Float,
        catching: GrainCatch = .anyDrift
    ) {
        self.position = position
        self.velocity = velocity
        self.area = area
        size = (area / SnowField.packing).squareRoot()
        self.turn = turn
        self.catching = catching
    }

    /// The clump `step` seconds later.
    /// - Parameters:
    ///   - step: Elapsed time, in seconds.
    /// - Returns: The clump pulled down and slowed by the air, moved along its new speed.
    func falling(for step: Float) -> Grain {
        let pulled: SIMD2<Float> = velocity - .init(0, Self.gravity * step)
        let slowed: SIMD2<Float> = pulled * exp(-Self.drag * step)
        return .init(
            position: position + slowed * step,
            velocity: slowed,
            area: area,
            turn: turn,
            catching: catching
        )
    }

    /// The clump falling through every ledge, off the screen.
    /// - Returns: The same clump, no drift catching it.
    func fallingThrough() -> Grain {
        .init(position: position, velocity: velocity, area: area, turn: turn, catching: .noDrift)
    }
}
