//
//  GrainTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct GrainTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let tolerance: Float = 0.001
    private static let front: SnowSurface = .mock(id: .window(3), frame: .init(x: 150, y: 450, width: 300, height: 250), zIndex: 0)
    private static let upper: SnowSurface = .mock(id: .window(1), frame: .init(x: 200, y: 400, width: 200, height: 200), zIndex: 1)
    private static let lower: SnowSurface = .mock(id: .window(2), frame: .init(x: 100, y: 0, width: 400, height: 300), zIndex: 2)

    private static func fieldWithSnowOnUpper() -> SnowField {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [upper]
        (1...1800).forEach { field.advance(to: Float($0) * frameDuration) }
        field.advance(to: 80)
        return field
    }

    @Test
    func `a grain lands on a lower ledge and piles its snow there`() throws {
        var field: SnowField = Self.fieldWithSnowOnUpper()
        let piled: Float = try #require(field.drifts[.window(1)]).volume

        field.surfaces = [Self.front, Self.upper, Self.lower]
        let falling: Float = field.grains.map(\.area).reduce(0, +)
        (1...120).forEach { field.advance(to: 80 + Float($0) * Self.frameDuration) }

        let upper: SnowDrift = try #require(field.drifts[.window(1)])
        let lower: SnowDrift = try #require(field.drifts[.window(2)])
        #expect(piled > 0)
        #expect(upper.volume == 0)
        #expect(abs(falling - piled) < piled * Self.tolerance)
        #expect(field.grains.isEmpty)
        #expect(abs(lower.volume - piled) < piled * Self.tolerance)
    }

    @Test
    func `a hard landing puffs powder that fades away`() {
        var field: SnowField = Self.fieldWithSnowOnUpper()

        field.surfaces = [Self.front, Self.upper, Self.lower]
        let puffed: Bool = (1...120)
            .map { frame in
                field.advance(to: 80 + Float(frame) * Self.frameDuration)
                return !field.puffs.isEmpty
            }
            .contains(true)
        (121...300).forEach { field.advance(to: 80 + Float($0) * Self.frameDuration) }

        #expect(puffed)
        #expect(field.puffs.isEmpty)
    }
}
