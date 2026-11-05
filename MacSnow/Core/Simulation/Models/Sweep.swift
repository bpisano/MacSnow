//
//  Sweep.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// The pointer passing fast between two frames, in points with the origin at the bottom left of the screen.
///
/// Sweeps the snow its brush crosses, from `reach` above the snow surface down to the ledge top.
struct Sweep: Equatable, Sendable {
    /// Width of the brush, in points.
    static let brush: Float = 12
    /// Pointer speed from which it sweeps, in points per second.
    static let slowest: Float = 120
    /// Height above the snow surface from which the brush touches it, in points.
    static let reach: Float = 5
    /// Share of the snow swept off each column the brush crosses.
    static let share: Float = 0.7
    /// Share of the pointer speed the swept snow is thrown with.
    static let carry: Float = 0.35
    /// Upward speed the swept snow is thrown with, in points per second.
    static let lift: Float = 160

    /// Where the pointer was at the previous frame.
    let start: SIMD2<Float>
    /// Where the pointer is now.
    let end: SIMD2<Float>
    /// Pointer speed, in points per second.
    let velocity: SIMD2<Float>

    /// Creates the sweep of a pointer moving from `start` to `end`.
    /// - Parameters:
    ///   - start: Where the pointer was.
    ///   - end: Where the pointer is now.
    ///   - duration: Elapsed time, in seconds.
    /// - Returns: `nil` when no time elapsed, or the pointer moved slower than `slowest`.
    init?(from start: SIMD2<Float>, to end: SIMD2<Float>, over duration: Float) {
        guard duration > 0 else {
            return nil
        }
        let velocity: SIMD2<Float> = (end - start) / duration
        guard (velocity * velocity).sum() > Self.slowest * Self.slowest else {
            return nil
        }
        self.start = start
        self.end = end
        self.velocity = velocity
    }

    /// Speed given to the snow it throws, in points per second.
    var impulse: SIMD2<Float> {
        Self.carry * velocity + .init(0, Self.lift)
    }

    private static func span(from start: Float, to end: Float, within range: ClosedRange<Float>) -> ClosedRange<Float>? {
        guard start != end else {
            return range.contains(start) ? 0...1 : nil
        }
        let bounds: (Float, Float) = (
            (range.lowerBound - start) / (end - start),
            (range.upperBound - start) / (end - start)
        )
        let low: Float = max(min(bounds.0, bounds.1), 0)
        let high: Float = min(max(bounds.0, bounds.1), 1)
        return low <= high ? low...high : nil
    }

    /// Where the pointer path first enters a box.
    /// - Parameters:
    ///   - across: The box's horizontal span, in points.
    ///   - upward: The box's vertical span, in points.
    /// - Returns: The first point of the path in the box, `nil` when the path misses it.
    func entry(across: ClosedRange<Float>, upward: ClosedRange<Float>) -> SIMD2<Float>? {
        guard
            let horizontal = Self.span(from: start.x, to: end.x, within: across),
            let vertical = Self.span(from: start.y, to: end.y, within: upward)
        else {
            return nil
        }
        let first: Float = max(horizontal.lowerBound, vertical.lowerBound)
        guard first <= min(horizontal.upperBound, vertical.upperBound) else {
            return nil
        }
        return start + (end - start) * first
    }
}
