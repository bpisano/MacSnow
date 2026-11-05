//
//  Puff.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation

/// A small cloud of powder, in points with the origin at the bottom left of the screen.
///
/// Drifts away from where it rose, slowed by the air, and fades out over its life.
struct Puff: Equatable, Sendable {
    /// Rate at which the air slows it, per second.
    static let drag: Float = 3

    /// Center.
    let position: SIMD2<Float>
    /// Speed, in points per second.
    let velocity: SIMD2<Float>
    /// Diameter, in points.
    let size: Float
    /// Opacity when it rises, from 0 to 1.
    let alpha: Float
    /// Time until it is gone, in seconds.
    let life: Float
    /// Time since it rose, in seconds.
    let age: Float

    /// Creates a cloud of powder.
    /// - Parameters:
    ///   - position: Center.
    ///   - velocity: Speed, in points per second.
    ///   - size: Diameter, in points.
    ///   - alpha: Opacity when it rises, from 0 to 1.
    ///   - life: Time until it is gone, in seconds.
    ///   - age: Time since it rose, in seconds.
    init(
        position: SIMD2<Float>,
        velocity: SIMD2<Float>,
        size: Float,
        alpha: Float,
        life: Float,
        age: Float = 0
    ) {
        self.position = position
        self.velocity = velocity
        self.size = size
        self.alpha = alpha
        self.life = life
        self.age = age
    }

    /// Whether it faded out.
    var isGone: Bool {
        age >= life
    }

    /// Opacity now, fading linearly from `alpha` to none over its life.
    var opacity: Float {
        alpha * max(1 - age / life, 0)
    }

    /// The cloud `step` seconds later.
    /// - Parameters:
    ///   - step: Elapsed time, in seconds.
    /// - Returns: The cloud older, slowed by the air, moved along its new speed.
    func spreading(for step: Float) -> Puff {
        let slowed: SIMD2<Float> = velocity * exp(-Self.drag * step)
        return .init(
            position: position + slowed * step,
            velocity: slowed,
            size: size,
            alpha: alpha,
            life: life,
            age: age + step
        )
    }
}
