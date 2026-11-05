//
//  DriftMotion.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation
import simd

/// How a drift rides its moving ledge: the pile lags on a spring and leans, and rough motion throws snow off.
///
/// The ledge speed is measured between the frames where the ledge actually moved, then smoothed,
/// so frames polled twice or skipped do not read as jolts.
/// A shake, a sharp jolt, or a fast lift each throw part of the drift.
struct DriftMotion: Sendable {
    /// Spring rate pulling the pile back over its ledge, critically damped, in radians per second.
    static let stiffness: Float = 18
    /// Farthest the pile lags behind its ledge, in points.
    static let mostOffset: Float = 6
    /// Time over which the measured ledge speed follows a change, in seconds.
    static let smoothing: Float = 0.05
    /// Time without motion after which the ledge counts as slowing down, in seconds.
    static let stillness: Float = 0.1
    /// Ledge acceleration from which the snow jolts off, in points per second squared.
    static let joltAcceleration: Float = 5200
    /// Shortest time between two jolts, in seconds.
    static let joltRest: Float = 0.5
    /// Snow a jolt throws, as a share of a full drift.
    static let joltShare: Float = 0.25
    /// Snow the first shaking swing throws, as a share of a full drift.
    static let swingShare: Float = 0.25
    /// Snow each further shaking swing throws on top of the previous one, as a share of a full drift.
    static let swingGrowth: Float = 0.1
    /// Most snow one shaking swing throws, as a share of a full drift.
    static let mostSwingShare: Float = 0.6
    /// Upward ledge speed from which the snow slides off, in points per second.
    static let liftSpeed: Float = 1500
    /// Snow a fast lift slides off, as a share of a full drift, half flying each way.
    static let liftShare: Float = 0.3
    /// Sideways speed of thrown snow, in points per second.
    static let fling: Float = 120
    /// Upward speed of thrown snow, in points per second.
    static let pop: Float = 40

    private static let restingSpeed: Float = 1

    /// Where the pile sits across its ledge, in points: negative when it lags left.
    private(set) var offset: Float = 0

    private var offsetVelocity: Float = 0
    private var velocity: SIMD2<Float> = .zero
    private var travel: SIMD2<Float> = .zero
    private var sampledAt: Float = 0
    private var swings: SwingDetector = .init()
    private var joltedAt: Float?
    private var isLifting: Bool = false

    /// Follows the ledge whose ends and top moved since the last call. Sideways, only the motion both ends share counts,
    /// the smaller one when they moved the same way, none otherwise, so a resize alone reads as still.
    /// The pile stays behind that motion, as far as `mostOffset`.
    /// - Parameters:
    ///   - left: How far the left end moved, in points.
    ///   - right: How far the right end moved, in points.
    ///   - top: How far the ledge top moved, in points.
    mutating func follow(left: Float, right: Float, top: Float) {
        let across: Float = left * right > 0 ? (abs(left) < abs(right) ? left : right) : 0
        travel += .init(across, top)
        offset = min(max(offset - across, -Self.mostOffset), Self.mostOffset)
    }

    /// Springs the pile back over its ledge for `step`, then measures the ledge motion up to `time`.
    /// - Parameters:
    ///   - time: The moment, in seconds.
    ///   - step: Elapsed time since the last call, in seconds.
    /// - Returns: The snow the motion throws off: one shake per jolt or shaking swing, two per lift.
    mutating func advance(to time: Float, for step: Float) -> [Shake] {
        spring(for: step)
        let elapsed: Float = time - sampledAt
        let isSlowing: Bool = velocity != .zero && elapsed >= Self.stillness
        guard elapsed > 0, travel != .zero || isSlowing else {
            return []
        }
        let measured: SIMD2<Float> = travel / elapsed
        travel = .zero
        sampledAt = time
        return sample(measured, over: elapsed, at: time)
    }

    /// Moves every moment the motion keeps back by `duration`, as the field clock moves back.
    /// - Parameters:
    ///   - duration: How far the clock moves back, in seconds.
    mutating func rewind(by duration: Float) {
        sampledAt -= duration
        joltedAt = joltedAt.map { $0 - duration }
        swings.rewind(by: duration)
    }

    private mutating func spring(for step: Float) {
        let decay: Float = exp(-Self.stiffness * step)
        let pull: Float = offsetVelocity + Self.stiffness * offset
        offset = (offset + pull * step) * decay
        offsetVelocity = (offsetVelocity - Self.stiffness * pull * step) * decay
    }

    private mutating func sample(_ measured: SIMD2<Float>, over elapsed: Float, at time: Float) -> [Shake] {
        let previous: SIMD2<Float> = velocity
        let followed: SIMD2<Float> = previous + (measured - previous) * (1 - exp(-elapsed / Self.smoothing))
        velocity = simd_length(followed) < Self.restingSpeed ? .zero : followed
        let acceleration: SIMD2<Float> = (velocity - previous) / elapsed
        return jolt(acceleration, at: time) + lift() + swing(at: time)
    }

    private mutating func jolt(_ acceleration: SIMD2<Float>, at time: Float) -> [Shake] {
        let isRested: Bool = joltedAt.map { time - $0 >= Self.joltRest } ?? true
        guard simd_length(acceleration) > Self.joltAcceleration, isRested else {
            return []
        }
        joltedAt = time
        let away: Float = acceleration.x > 0 ? -1 : 1
        return [.init(share: Self.joltShare, impulse: .init(away * Self.fling, Self.pop))]
    }

    private mutating func lift() -> [Shake] {
        let lifting: Bool = velocity.y > Self.liftSpeed
        defer { isLifting = lifting }
        guard lifting, !isLifting else {
            return []
        }
        return [-1, 1].map { side in
            .init(share: Self.liftShare / 2, impulse: .init(side * Self.fling, 0))
        }
    }

    private mutating func swing(at time: Float) -> [Shake] {
        guard let reversals = swings.track(velocity.x, at: time) else {
            return []
        }
        let growth: Float = Self.swingGrowth * Float(reversals - SwingDetector.shakeReversals)
        let share: Float = min(Self.swingShare + growth, Self.mostSwingShare)
        let away: Float = velocity.x > 0 ? -1 : 1
        return [.init(share: share, impulse: .init(away * Self.fling, Self.pop))]
    }
}
