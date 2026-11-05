//
//  Landing.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation

/// Where and when falling snow first reaches a drift.
struct Landing: Sendable {
    private static let crossingSteps: Int = 12

    /// The ledge whose drift catches the snow.
    let drift: SnowSurfaceID
    /// Where the snow reaches the drift, in points.
    let point: SIMD2<Float>
    /// When the snow reaches the drift.
    let time: Float

    /// Solves where `path` first reaches `drift`'s snow, or its bare ledge top, between `start` and `end`.
    /// - Parameters:
    ///   - path: Where the falling snow is at a time.
    ///   - start: Search start.
    ///   - end: Search end.
    ///   - drift: The drift to land on.
    /// - Returns: `nil` when the path does not reach it, or reaches a ledge top a window in front covers.
    init?(of path: (Float) -> SIMD2<Float>, from start: Float, to end: Float, on drift: SnowDrift) {
        guard let time = Self.crossing(of: path, from: start, to: end, on: drift) else {
            return nil
        }
        let point: SIMD2<Float> = path(time)
        guard !drift.isCovered(at: point.x) else {
            return nil
        }
        self.drift = drift.id
        self.point = point
        self.time = time
    }

    /// Solves when a path first reaches `drift`'s snow surface, or its bare ledge top, from above or from the side.
    /// - Parameters:
    ///   - path: Where the path is at a time.
    ///   - start: Search start, when the path must be outside the snow, or in snow that rose under it.
    ///   - end: Search end.
    ///   - drift: The drift to reach.
    /// - Returns: The crossing time within a few milliseconds, `start` when the path starts in the snow,
    ///   `nil` when the path does not reach the snow between `start` and `end`, or only enters under the ledge top.
    static func crossing(
        of path: (Float) -> SIMD2<Float>,
        from start: Float,
        to end: Float,
        on drift: SnowDrift
    ) -> Float? {
        let first: SIMD2<Float> = path(start)
        guard !drift.buries(first) else {
            return first.y >= drift.top ? start : nil
        }
        let samples: [Float] = (1...crossingSteps).map { start + (end - start) * Float($0) / Float(crossingSteps) }
        guard let buried = samples.first(where: { drift.buries(path($0)) }) else {
            return nil
        }
        let bounds: (above: Float, below: Float) = (0..<crossingSteps).reduce((start, buried)) { bounds, _ in
            let middle: Float = (bounds.above + bounds.below) / 2
            return drift.buries(path(middle)) ? (bounds.above, middle) : (middle, bounds.below)
        }
        return path(bounds.above).y >= drift.top ? bounds.below : nil
    }
}
