//
//  Overhang.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Snow gathered past one end of the ledge, breaking off in chunks of irregular size, then resting a while of irregular length.
struct Overhang: Sendable {
    /// Least snow breaking off at once, in square points.
    private static let smallestChunk: Float = 24
    /// Most extra snow a chunk takes over `smallestChunk`, in square points.
    private static let chunkSpread: Float = 24
    /// Least time the end rests after a chunk breaks off, in seconds.
    private static let shortestRest: Float = 15
    /// Most extra rest over `shortestRest`, in seconds, a larger chunk resting longer.
    private static let restSpread: Float = 30
    private static let phaseStep: Float = 0.618_034

    /// Snow gathered, in square points.
    private(set) var area: Float = 0

    private var phase: Float = 0
    private var restsUntil: Float?

    /// Adds `overflow` to the snow gathered. Once a chunk's worth gathered, it all breaks off, and the end rests.
    /// While it rests, it gathers a chunk's worth at most: the snow overflowing past it melts away.
    /// - Parameters:
    ///   - overflow: Snow area past capacity, in square points.
    ///   - time: The moment, in seconds.
    /// - Returns: The snow area breaking off, `nil` while it holds or rests.
    mutating func gather(_ overflow: Float, at time: Float) -> Float? {
        let chunk: Float = Self.smallestChunk + Self.chunkSpread * phase
        if let restsUntil, time < restsUntil {
            area = min(area + overflow, chunk)
            return nil
        }
        area += overflow
        guard area >= chunk else {
            return nil
        }
        restsUntil = time + Self.shortestRest + Self.restSpread * phase
        return drop()
    }

    /// Lets all the snow gathered fall, the next chunk a different size. The rest under way, if any, goes on.
    /// - Returns: The snow area falling, in square points.
    mutating func drop() -> Float {
        let fallen: Float = area
        area = 0
        phase = (phase + Self.phaseStep).truncatingRemainder(dividingBy: 1)
        return fallen
    }

    /// Moves the end of the rest under way, if any, back by `duration`, as the clock moves back.
    /// - Parameters:
    ///   - duration: How far the clock moves back, in seconds.
    mutating func rewind(by duration: Float) {
        restsUntil = restsUntil.map { $0 - duration }
    }
}
