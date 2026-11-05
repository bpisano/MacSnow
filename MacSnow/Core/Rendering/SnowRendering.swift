//
//  SnowRendering.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Metal
import QuartzCore

/// Draws frames of falling flakes, grains, puffs and drifts into drawables, from any thread.
protocol SnowRendering: Sendable {
    /// The GPU the drawables must be created on.
    var device: any MTLDevice { get }

    /// Copies `flakes` to GPU memory, once each time they change.
    /// - Parameters:
    ///   - flakes: The flakes to draw from now on.
    /// - Returns: The GPU copy, `nil` when there is no flake to draw.
    func upload(_ flakes: [SnowFlake]) -> (any MTLBuffer)?

    /// Draws `drifts`, `sprites` and `flakes` into `drawable` and presents it.
    /// - Parameters:
    ///   - flakes: The flakes, as returned by `upload(_:)`.
    ///   - sprites: The grains and puffs, uploaded each frame.
    ///   - drifts: The drifts, back to front, uploaded each frame.
    ///   - uniforms: The state of this frame.
    ///   - drawable: The drawable to fill and present.
    func render(
        _ flakes: (any MTLBuffer)?,
        sprites: [SnowSprite],
        drifts: [SnowDrift],
        with uniforms: SnowUniforms,
        into drawable: any CAMetalDrawable
    )
}
