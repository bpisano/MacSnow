//
//  OcclusionTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct OcclusionTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let ledge: SnowSurface = .mock(id: .window(7), frame: .init(x: 100, y: 200, width: 400, height: 300), zIndex: 1)
    private static let leftHalf: SnowSurface = .mock(id: .window(3), frame: .init(x: 0, y: 0, width: 300, height: 600), zIndex: 0)

    @Test
    func `a drift is hidden only by the windows in front, clipped to its bounds`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        let above: SnowSurface = .mock(id: .window(2), frame: .init(x: 0, y: 800, width: 600, height: 100), zIndex: 0)
        let behind: SnowSurface = .mock(id: .window(9), frame: .init(x: 250, y: 0, width: 400, height: 600), zIndex: 3)

        field.surfaces = [above, .mock(id: .window(3), frame: Self.leftHalf.frame, zIndex: 1), .mock(id: .window(7), frame: Self.ledge.frame, zIndex: 2), behind]

        let drift: SnowDrift = try #require(field.drifts[.window(7)])
        #expect(drift.occluders == [.init(x: 100, y: 499, width: 200, height: 17)])
    }

    @Test
    func `a window moving over a drift drops the snow it covers and keeps the rest`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.ledge]
        (1...3600).forEach { field.advance(to: Float($0) * Self.frameDuration) }
        let heights: [Float] = try #require(field.drifts[.window(7)]).heights

        field.surfaces = [Self.leftHalf, Self.ledge]

        let drift: SnowDrift = try #require(field.drifts[.window(7)])
        #expect(heights.prefix(80).contains { $0 > 0 })
        #expect(drift.heights.prefix(80).allSatisfy { $0 == 0 })
        #expect(drift.heights.suffix(80) == heights.suffix(80))
    }

    @Test
    func `snow covered before stays gone once the drift is in front again`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.ledge]
        (1...3600).forEach { field.advance(to: Float($0) * Self.frameDuration) }
        field.surfaces = [Self.leftHalf, Self.ledge]

        field.surfaces = [.mock(id: .window(7), frame: Self.ledge.frame, zIndex: 0), .mock(id: .window(3), frame: Self.leftHalf.frame, zIndex: 1)]

        let drift: SnowDrift = try #require(field.drifts[.window(7)])
        #expect(drift.occluders.isEmpty)
        #expect(drift.heights.prefix(80).allSatisfy { $0 == 0 })
    }

    @Test
    func `no snow piles on the covered part of a ledge`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.leftHalf, Self.ledge]

        (1...3600).forEach { field.advance(to: Float($0) * Self.frameDuration) }

        let drift: SnowDrift = try #require(field.drifts[.window(7)])
        #expect(drift.heights.prefix(80).allSatisfy { $0 == 0 })
        #expect(drift.heights.suffix(80).contains { $0 > 0 })
    }
}
