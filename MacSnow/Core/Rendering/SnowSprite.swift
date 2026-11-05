//
//  SnowSprite.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// One grain or puff on the GPU, for one frame. Field order matches `SnowSprite` in `Snow.metal`.
struct SnowSprite: Equatable, Sendable {
    /// Center, in points.
    let center: SIMD2<Float>
    /// Diameter, in points.
    let size: Float
    /// Opacity, from 0 to 1.
    let alpha: Float
    /// How irregular and shaded the outline is: 0 for a soft round puff, 1 for a lumpy grain.
    let lump: Float
    /// Turn of the outline, in radians.
    let turn: Float

    /// Captures `grain` as it is now.
    /// - Parameters:
    ///   - grain: The clump to draw.
    init(grain: Grain) {
        center = grain.position
        size = grain.size
        alpha = 1
        lump = 1
        turn = grain.turn
    }

    /// Captures `puff` as it is now.
    /// - Parameters:
    ///   - puff: The powder cloud to draw.
    init(puff: Puff) {
        center = puff.position
        size = puff.size
        alpha = puff.opacity
        lump = 0
        turn = 0
    }
}
