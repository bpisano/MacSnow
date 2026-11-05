//
//  ClearTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct ClearTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let ledge: SnowSurface = .mock(id: .window(7), frame: .init(x: 100, y: 200, width: 400, height: 300), zIndex: 0)
    private static let ground: SnowSurface = .mock(id: .ground, frame: .init(x: 0, y: 0, width: 600, height: 0), zIndex: 1)

    private static func snowyField() -> SnowField {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [ledge, ground]
        (1...1800).forEach { field.advance(to: Float($0) * frameDuration) }
        return field
    }

    @Test
    func `clearing leaves every drift empty`() {
        var field: SnowField = Self.snowyField()
        #expect(field.drifts.values.allSatisfy { $0.volume > 0 })

        field.clear()

        #expect(field.drifts.values.allSatisfy { $0.peak == 0 })
        #expect(!field.grains.isEmpty)
        #expect(field.grains.allSatisfy { $0.catching == .noDrift })
    }

    @Test
    func `cleared snow falls off the screen within two seconds while snow keeps falling`() {
        var field: SnowField = Self.snowyField()
        let piled: Float = field.drifts.values.map(\.volume).reduce(0, +)

        field.clear()
        (1...120).forEach { field.advance(to: 30 + Float($0) * Self.frameDuration) }

        let piledAgain: Float = field.drifts.values.map(\.volume).reduce(0, +)
        #expect(field.grains.allSatisfy { $0.catching != .noDrift })
        #expect(piledAgain < piled / 5)
        #expect(field.isSpawning)
        #expect(!field.flakes.isEmpty)
    }
}
