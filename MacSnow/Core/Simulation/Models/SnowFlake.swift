//
//  SnowFlake.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation

/// One flake falling on an analytic path, in points with the origin at the bottom left of the screen.
///
/// Uploaded to the GPU as is: the field order matches `SnowFlake` in `Snow.metal`, and so do the waves.
struct SnowFlake: Equatable, Sendable {
    /// The swings summed into the sideways flutter. Their paces never line up, so the flutter never repeats,
    /// and their weights sum to 1, so it stays within `flutter`.
    static let flutterWaves: [FlakeWave] = [
        .init(pace: 1, weight: 0.58, twist: 1, offset: 0),
        .init(pace: 1.73, weight: 0.29, twist: 2.17, offset: 0.9),
        .init(pace: 2.91, weight: 0.13, twist: 3.61, offset: 2.6)
    ]
    /// The slow swing bobbing the flake up and down around its mean fall.
    static let bobWave: FlakeWave = .init(pace: 0.55, weight: 1, twist: 1.19, offset: 4.1)

    /// Time of birth, in seconds of the field clock.
    let born: Float
    /// Time from which the flake is below the screen for good.
    let gone: Float
    /// Distance from the left edge of the flutter's center line, without wind.
    let lane: Float
    /// Height of the mean fall at birth.
    let top: Float
    /// Mean falling speed, in points per second.
    let speed: Float
    /// Amplitude of the bob around the mean fall, in points.
    let bob: Float
    /// Angular speed shared by every wave, in radians per second.
    let tempo: Float
    /// Sets the waves' phases apart from other flakes, in radians.
    let seed: Float
    /// Amplitude of the sideways flutter, in points.
    let flutter: Float
    /// Share of the wind's distance the flake follows, from 0 to 1.
    let windShare: Float
    /// Diameter, in points.
    let size: Float
    /// Opacity, from 0 to 1.
    let opacity: Float
    /// Share of the radius blurred at the edge, from 0 to 1.
    let blur: Float

    /// `across` wrapped across the screen width, `SnowField.margin` past each edge.
    /// - Parameters:
    ///   - across: Distance from the left edge, in points.
    ///   - width: Screen width, in points.
    /// - Returns: The same place within the wrapped span, in points.
    static func wrapped(_ across: Float, width: Float) -> Float {
        let span: Float = width + 2 * SnowField.margin
        let laps: Float = (across + SnowField.margin) / span
        return (laps - laps.rounded(.down)) * span - SnowField.margin
    }

    /// Where the flake is at `time`, wrapped across the screen width.
    /// - Parameters:
    ///   - time: The moment, in seconds of the field clock.
    ///   - wind: Distance the wind had blown by `time`, in points.
    ///   - width: Screen width, crossed whole `SnowField.margin` past each edge before wrapping, in points.
    /// - Returns: The flake center, in points.
    func position(at time: Float, wind: Float, width: Float) -> SIMD2<Float> {
        let age: Float = time - born
        let angle: Float = tempo * age
        let fluttering: Float = Self.flutterWaves.reduce(0) { $0 + $1.value(at: angle, seed: seed) }
        return .init(
            Self.wrapped(lane + windShare * wind + flutter * fluttering, width: width),
            top - speed * age + bob * Self.bobWave.value(at: angle, seed: seed)
        )
    }

    /// The same flake on clocks moved back by `duration` and a wind whose distance blown dropped by `wind`:
    /// it stays where it is, its lane wrapped across the screen width.
    /// - Parameters:
    ///   - duration: How far the clock moves back, in seconds.
    ///   - wind: The wind distance forgotten, in points.
    ///   - width: Screen width, in points.
    /// - Returns: The flake on the moved-back clocks.
    func rewound(by duration: Float, wind: Float, width: Float) -> SnowFlake {
        .init(
            born: born - duration,
            gone: gone - duration,
            lane: Self.wrapped(lane + windShare * wind, width: width),
            top: top,
            speed: speed,
            bob: bob,
            tempo: tempo,
            seed: seed,
            flutter: flutter,
            windShare: windShare,
            size: size,
            opacity: opacity,
            blur: blur
        )
    }
}

extension SnowFlake {
    /// A flake 500 pt high falling straight at 50 pt/s, for previews and tests.
    static func mock(
        born: Float = 0,
        gone: Float = .infinity,
        lane: Float = 100,
        top: Float = 500,
        speed: Float = 50,
        bob: Float = 0,
        tempo: Float = 1,
        seed: Float = 0,
        flutter: Float = 0,
        windShare: Float = 1,
        size: Float = 2,
        opacity: Float = 1,
        blur: Float = 0.5
    ) -> SnowFlake {
        .init(
            born: born,
            gone: gone,
            lane: lane,
            top: top,
            speed: speed,
            bob: bob,
            tempo: tempo,
            seed: seed,
            flutter: flutter,
            windShare: windShare,
            size: size,
            opacity: opacity,
            blur: blur
        )
    }
}
