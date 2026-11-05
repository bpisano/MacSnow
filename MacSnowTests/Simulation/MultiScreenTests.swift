//
//  MultiScreenTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct MultiScreenTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let screens: [CGRect] = [
        .init(x: 0, y: 0, width: 600, height: 1000),
        .init(x: 600, y: 0, width: 600, height: 1000)
    ]

    @Test
    func `a window spanning two screens piles snow on each part by its share of the ledge`() throws {
        let window: SnowSurface = .mock(id: .window(5), frame: .init(x: 300, y: 200, width: 500, height: 300))
        var fields: [SnowField] = Self.screens.map { screen in
            var field: SnowField = .init(width: Float(screen.width), height: Float(screen.height), random: SeededRandomNumberGenerator())
            field.surfaces = SnowSurface.frontToBack(windows: [window], dockTileRow: nil, screen: screen).map { surface in
                .mock(
                    id: surface.id,
                    frame: surface.frame.offsetBy(dx: -screen.minX, dy: -screen.minY),
                    zIndex: surface.zIndex,
                    cornerRadius: surface.cornerRadius
                )
            }
            return field
        }

        (1...7200).forEach { frame in
            fields.indices.forEach { fields[$0].advance(to: Float(frame) * Self.frameDuration) }
        }

        let left: Float = try #require(fields[0].drifts[.window(5)]).volume
        let right: Float = try #require(fields[1].drifts[.window(5)]).volume
        #expect(right > 0)
        #expect(abs(left / right - 1.5) < 0.3)
    }
}
