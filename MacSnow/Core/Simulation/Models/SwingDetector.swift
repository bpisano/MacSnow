//
//  SwingDetector.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Tells a shake from a drag: a window swinging left and right fast, reversing a few times in a short while.
///
/// A swing is a stretch of horizontal motion faster than `swingSpeed` in one direction.
/// A reversal is a swing starting the other way from the previous one.
struct SwingDetector: Sendable {
    /// Horizontal speed from which motion counts as a swing, in points per second.
    static let swingSpeed: Float = 200
    /// How long a reversal counts towards a shake, in seconds.
    static let memory: Float = 1
    /// Reversals within `memory` making a shake.
    static let shakeReversals: Int = 3

    /// Direction of the last swing, `nil` before the first one.
    private var swingDirection: FloatingPointSign?
    private var reversals: [Float] = []

    /// Follows the window's horizontal speed at `time`.
    /// - Parameters:
    ///   - velocity: Horizontal speed, in points per second, positive rightwards.
    ///   - time: The moment, in seconds, later than the last one tracked.
    /// - Returns: The reversals within `memory`, this one included, when this speed reverses the swing
    ///   into a shake; `nil` otherwise.
    mutating func track(_ velocity: Float, at time: Float) -> Int? {
        reversals.removeAll { $0 <= time - Self.memory }
        guard abs(velocity) > Self.swingSpeed else {
            return nil
        }
        let direction: FloatingPointSign = velocity.sign
        let previous: FloatingPointSign? = swingDirection
        swingDirection = direction
        guard let previous, previous != direction else {
            return nil
        }
        reversals.append(time)
        return reversals.count >= Self.shakeReversals ? reversals.count : nil
    }

    /// Moves every reversal kept back by `duration`, as the clock moves back.
    /// - Parameters:
    ///   - duration: How far the clock moves back, in seconds.
    mutating func rewind(by duration: Float) {
        reversals = reversals.map { $0 - duration }
    }
}
