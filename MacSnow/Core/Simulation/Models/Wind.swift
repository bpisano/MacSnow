//
//  Wind.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Horizontal wind wandering slowly between two opposite gales.
struct Wind: Equatable, Sendable {
    /// Highest speed either way, in points per second.
    static let strongest: Float = 20

    private static let gustiness: Float = 5

    /// Current speed, in points per second, positive to the right.
    private(set) var speed: Float
    /// Distance blown since the wind rose, in points.
    private(set) var offset: Float

    /// Creates a wind.
    /// - Parameters:
    ///   - speed: Starting speed, in points per second.
    ///   - offset: Distance already blown, in points.
    init(speed: Float = 0, offset: Float = 0) {
        self.speed = speed
        self.offset = offset
    }

    /// Lets the wind blow for `duration`, its speed taking one random walk step.
    /// - Parameters:
    ///   - duration: Elapsed time, in seconds.
    ///   - turn: Random draw from -1 to 1, the direction and strength of the step.
    mutating func blow(for duration: Float, turning turn: Float) {
        let step: Float = turn * Self.gustiness * duration.squareRoot()
        speed = min(max(speed + step, -Self.strongest), Self.strongest)
        offset += speed * duration
    }

    /// Forgets the distance blown, keeping the speed, so it never grows large enough to lose precision.
    /// - Returns: The distance forgotten, in points.
    mutating func resetOffset() -> Float {
        let blown: Float = offset
        offset = 0
        return blown
    }
}
