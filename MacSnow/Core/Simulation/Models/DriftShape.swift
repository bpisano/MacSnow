//
//  DriftShape.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation

/// How snow settles across the columns of a drift: held up to each column's capacity, spread as a rounded bump,
/// slumped to the angle of repose, smoothed round.
enum DriftShape {
    /// Steepest angle the snow holds before toppling, in degrees.
    static let reposeAngle: Float = 30
    /// Steepest slope the snow holds before toppling, height over width.
    static let repose: Float = .init(tan(Double(reposeAngle) * .pi / 180))
    /// Half-width of a deposit's bump per point of the deposit's diameter, the square root of its area.
    static let spreadPerDiameter: Float = 1.7
    /// Narrowest a deposit spreads on each side of its column, in columns.
    static let narrowestSpread: Int = 3
    /// Widest a deposit spreads on each side of its column, in columns.
    static let widestSpread: Int = 20
    /// Share of the height difference flowing between two neighbouring columns on each smoothing pass.
    static let smoothing: Float = 0.2

    private static let runoff: Float = 1.0 / 3.0
    private static let sides: [Int] = [-1, 1]
    private static let slumpPasses: Int = 64
    private static let smoothingPasses: Int = 3
    private static let settled: Float = 0.002

    /// Most snow each column of a ledge holds: none over its rounded corners, then a ramp up to `depth`.
    /// - Parameters:
    ///   - width: Width of the ledge, in points.
    ///   - cornerRadius: Radius of the ledge's rounded corners, in points.
    ///   - depth: Most snow a column holds, in points.
    ///   - ramp: Distance past a corner over which capacity grows to `depth`, in points; `nil` for no corners and no ramp.
    ///   - columnWidth: Width of one column, in points.
    /// - Returns: The capacity of each column, left to right, in points.
    static func capacity(width: Float, cornerRadius: Float, depth: Float, ramp: Float?, columnWidth: Float) -> [Float] {
        let count: Int = max(Int((width / columnWidth).rounded(.up)), 1)
        return (0..<count).map { column in
            let center: Float = (Float(column) + 0.5) * columnWidth
            let fromEnd: Float = min(center, width - center)
            let share: Float = ramp.map { (fromEnd - cornerRadius) / $0 } ?? 1
            return depth * min(max(share, 0), 1)
        }
    }

    /// Spreads `volume` as a raised-cosine bump centered on `column`, its half-width `spreadPerDiameter` times
    /// the deposit's diameter, from `narrowestSpread` to `widestSpread` columns.
    /// - Parameters:
    ///   - volume: Snow area, in square points.
    ///   - column: The column the snow lands on.
    ///   - heights: The snow height of each column, in points.
    ///   - columnWidth: Width of one column, in points.
    static func spread(_ volume: Float, at column: Int, over heights: inout [Float], columnWidth: Float) {
        let halfWidth: Int = .init((spreadPerDiameter * volume.squareRoot() / columnWidth).rounded())
        let radius: Int = min(max(halfWidth, narrowestSpread), widestSpread)
        let bump: Range<Int> = max(column - radius, 0)..<min(column + radius + 1, heights.count)
        let weights: [Float] = bump.map { 1 + cos(Float.pi * Float($0 - column) / Float(radius + 1)) }
        let total: Float = weights.reduce(0, +)
        zip(bump, weights).forEach { heights[$0] += volume * $1 / total / columnWidth }
    }

    /// Slumps snow off any column standing steeper than `repose` over a neighbour within `columns`, keeping its volume:
    /// each pass, a column hands `runoff` of its excess to each lower neighbour, sweeping one way then the other,
    /// until no excess is left.
    /// - Parameters:
    ///   - columns: The columns to settle.
    ///   - heights: The snow height of each column, in points.
    ///   - columnWidth: Width of one column, in points.
    static func slump(_ columns: Range<Int>, of heights: inout [Float], columnWidth: Float) {
        let talus: Float = repose * columnWidth
        for pass in 0..<slumpPasses {
            let forward: Bool = pass.isMultiple(of: 2)
            var steepest: Float = 0
            for step in 0..<columns.count {
                let column: Int = forward ? columns.lowerBound + step : columns.upperBound - 1 - step
                for side in sides {
                    let neighbour: Int = column + side
                    let excess: Float = columns.contains(neighbour) ? heights[column] - heights[neighbour] - talus : 0
                    guard excess > 0 else {
                        continue
                    }
                    heights[column] -= runoff * excess
                    heights[neighbour] += runoff * excess
                    steepest = max(steepest, excess)
                }
            }
            guard steepest > settled else {
                return
            }
        }
    }

    /// Lets `smoothing` of the height difference flow between neighbours within `columns`, all at once, a few times,
    /// keeping its volume: peaks round off, hollows fill.
    /// - Parameters:
    ///   - columns: The columns to smooth.
    ///   - heights: The snow height of each column, in points.
    static func smooth(_ columns: Range<Int>, of heights: inout [Float]) {
        for _ in 0..<smoothingPasses {
            let before: [Float] = .init(heights[columns])
            for column in columns.dropLast() {
                let offset: Int = column - columns.lowerBound
                let flow: Float = smoothing * (before[offset] - before[offset + 1])
                heights[column] -= flow
                heights[column + 1] += flow
            }
        }
    }
}
