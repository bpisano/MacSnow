//
//  Spill.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Snow leaving a drift, about to fall as grains.
struct Spill: Equatable, Sendable {
    /// Where the snow falls from, in screen points.
    let position: SIMD2<Float>
    /// Snow area, in square points.
    let area: Float

    /// Gathers `spills` in order: each joins the last clump while it holds less than `area` and lies within `reach` of it.
    /// - Parameters:
    ///   - spills: The snow leaving, in order.
    ///   - area: Snow area from which a clump takes no more spills, in square points.
    ///   - reach: Farthest a spill lies from a clump, along each axis, to join it, in points.
    /// - Returns: The clumps, in order.
    static func clumps(of spills: [Spill], upTo area: Float, within reach: Float) -> [Spill] {
        spills.reduce(into: []) { clumps, spill in
            guard
                let last = clumps.last,
                last.area < area,
                abs(last.position.x - spill.position.x) <= reach,
                abs(last.position.y - spill.position.y) <= reach
            else {
                clumps.append(spill)
                return
            }
            clumps[clumps.count - 1] = last.merged(with: spill)
        }
    }

    /// This snow and `other` falling together.
    /// - Parameters:
    ///   - other: More snow leaving a drift.
    /// - Returns: Both areas, falling from their area-weighted center.
    func merged(with other: Spill) -> Spill {
        let area: Float = area + other.area
        return .init(position: (position * self.area + other.position * other.area) / area, area: area)
    }

    /// This snow broken into pieces falling from the same place.
    /// - Parameters:
    ///   - weights: Relative size of each piece.
    /// - Returns: One spill per weight, its share of the area.
    func crumbled(into weights: [Float]) -> [Spill] {
        let total: Float = weights.reduce(0, +)
        return weights.map { .init(position: position, area: area * $0 / total) }
    }
}
