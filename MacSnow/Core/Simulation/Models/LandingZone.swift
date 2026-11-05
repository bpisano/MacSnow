//
//  LandingZone.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation

/// The drifts falling snow may land on, banded by the height of their ledge top.
struct LandingZone: Sendable {
    private static let bandHeight: Float = 32

    private let drifts: [SnowDrift]
    private let reaches: [Reach]
    private let lowestTop: Float
    private let deepest: Float
    private let bands: [[Int]]

    /// Creates the zone of `drifts`.
    /// - Parameters:
    ///   - drifts: The drifts, front to back.
    init(drifts: [SnowDrift]) {
        self.drifts = drifts
        reaches = drifts.map(Reach.init(of:))
        let tops: [Float] = reaches.map(\.top)
        let lowestTop: Float = tops.min() ?? 0
        let topBands: [Int] = tops.map { Self.band(of: $0, above: lowestTop) }
        var bands: [[Int]] = .init(repeating: [], count: (topBands.max() ?? -1) + 1)
        for (index, band) in topBands.enumerated() {
            bands[band].append(index)
        }
        self.lowestTop = lowestTop
        deepest = drifts.map(\.depth).max() ?? 0
        self.bands = bands
    }

    private static func band(of height: Float, above floor: Float) -> Int {
        Int(((height - floor) / bandHeight).rounded(.down))
    }

    /// Solves where `path` first reaches one of the drifts between `start` and `end`. Only the drifts whose ledge top
    /// lies between the path's start and its end, their depth below, and whose span meets the span between its start
    /// and its end, are searched.
    /// - Parameters:
    ///   - path: Where the falling snow is at a time.
    ///   - start: Search start.
    ///   - end: Search end.
    ///   - catching: Which drifts catch the snow.
    /// - Returns: The earliest landing, `nil` when the path reaches no drift.
    func landing(
        of path: (Float) -> SIMD2<Float>,
        from start: Float,
        to end: Float,
        catching: GrainCatch
    ) -> Landing? {
        let arrival: SIMD2<Float> = path(end)
        let lowest: Int = max(Self.band(of: arrival.y - deepest, above: lowestTop), 0)
        guard lowest < bands.count else {
            return nil
        }
        let departure: SIMD2<Float> = path(start)
        let highest: Int = min(Self.band(of: departure.y, above: lowestTop), bands.count - 1)
        guard lowest <= highest else {
            return nil
        }
        return bands[lowest...highest]
            .joined()
            .filter { reaches[$0].holds(from: departure, to: arrival) && catching.allows(drifts[$0].id) }
            .compactMap { Landing(of: path, from: start, to: end, on: drifts[$0]) }
            .min { $0.time < $1.time }
    }
}

private extension LandingZone {
    struct Reach {
        let left: Float
        let right: Float
        let top: Float
        let ceiling: Float

        init(of drift: SnowDrift) {
            left = drift.left
            right = drift.right
            top = drift.top
            ceiling = drift.top + drift.depth
        }

        func holds(from departure: SIMD2<Float>, to arrival: SIMD2<Float>) -> Bool {
            departure.y >= top
                && arrival.y <= ceiling
                && min(departure.x, arrival.x) < right
                && max(departure.x, arrival.x) >= left
        }
    }
}
