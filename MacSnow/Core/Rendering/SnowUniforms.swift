//
//  SnowUniforms.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// The per-frame state every flake shares on the GPU. Field order matches `SnowUniforms` in `Snow.metal`.
struct SnowUniforms: Equatable, Sendable {
    /// Screen width, in points.
    let width: Float
    /// Screen height, in points.
    let height: Float
    /// Field clock, in seconds.
    let now: Float
    /// Distance the wind blew, in points.
    let wind: Float
    /// Wind speed, in points per second.
    let windSpeed: Float
    /// Pixels per point.
    let scale: Float

    /// Captures `field` as it is now.
    /// - Parameters:
    ///   - field: The flakes' field.
    ///   - scale: Pixels per point of the screen.
    init(field: SnowField, scale: Float) {
        width = field.width
        height = field.height
        now = field.now
        wind = field.wind.offset
        windSpeed = field.wind.speed
        self.scale = scale
    }
}
