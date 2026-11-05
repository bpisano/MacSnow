//
//  MeltTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct MeltTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let ledge: SnowSurface = .mock(id: .window(7), frame: .init(x: 100, y: 200, width: 400, height: 300), zIndex: 0)
    private static let ground: SnowSurface = .mock(id: .ground, frame: .init(x: 0, y: 0, width: 600, height: 0), zIndex: 1)

    @Test
    func `melting lowers every column down to bare ledge`() {
        var drift: SnowDrift = .init(on: Self.ledge)
        _ = (0..<400).flatMap { drift.deposit(6, at: 100 + Float($0)) }
        let heights: [Float] = drift.heights

        drift.melt(by: 1)

        #expect(zip(drift.heights, heights).allSatisfy { $0 == max($1 - 1, 0) })

        drift.melt(by: SnowDrift.deepest)

        #expect(drift.peak == 0)
    }

    @Test
    func `drifts melt to nothing once snow stops`() {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.ledge, Self.ground]
        (1...1800).forEach { field.advance(to: Float($0) * Self.frameDuration) }
        #expect(field.drifts.values.allSatisfy { $0.peak > 0 })

        field.stopSpawning()
        let start: Float = field.now
        let drained: Int? = (1...6000).first { frame in
            field.advance(to: start + Float(frame) * Self.frameDuration)
            return field.isEmpty
        }

        #expect(drained != nil)
        #expect(field.drifts.values.allSatisfy { $0.volume == 0 })
    }

    @Test
    func `drifts do not melt while snow falls`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.ledge]
        (1...1800).forEach { field.advance(to: Float($0) * Self.frameDuration) }
        let piled: Float = try #require(field.drifts[.window(7)]).volume

        (1801...1860).forEach { field.advance(to: Float($0) * Self.frameDuration) }

        let drift: SnowDrift = try #require(field.drifts[.window(7)])
        #expect(drift.volume >= piled)
    }
}
