//
//  GroundAndDockTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct GroundAndDockTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let screen: CGRect = .init(x: 0, y: 0, width: 600, height: 1000)
    private static let dockTileRow: CGRect = .init(x: 100, y: 10, width: 400, height: 60)

    @Test
    func `the ground drift rests on the screen bottom, as deep at its ends as in its middle`() {
        let drift: SnowDrift = .init(on: .mock(id: .ground, frame: .init(x: 0, y: 0, width: 600, height: 0), cornerRadius: 0))

        #expect(drift.left == 0)
        #expect(drift.top == 0)
        #expect(drift.width == 600)
        #expect(drift.depth == SnowDrift.groundDeepest)
        #expect(drift.capacity.allSatisfy { $0 == SnowDrift.groundDeepest })
    }

    @Test
    func `the Dock drift tapers over its rounded ends`() {
        let drift: SnowDrift = .init(on: .mock(id: .dock, frame: Self.dockTileRow, cornerRadius: 16))

        #expect(drift.depth == SnowDrift.deepest)
        #expect(drift.capacity.prefix(6).allSatisfy { $0 == 0 })
        #expect(drift.capacity[100] == SnowDrift.deepest)
    }

    @Test
    func `snow with no window below piles on the ground`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = SnowSurface.frontToBack(windows: [], dockTileRow: nil, screen: Self.screen)

        (1...1800).forEach { field.advance(to: Float($0) * Self.frameDuration) }

        let ground: SnowDrift = try #require(field.drifts[.ground])
        #expect(ground.volume > 0)
    }

    @Test
    func `the Dock in front of a window hides its pile there`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        let window: SnowSurface = .mock(id: .window(3), frame: .init(x: 0, y: 0, width: 300, height: 40), zIndex: 0)
        field.surfaces = SnowSurface.frontToBack(windows: [window], dockTileRow: Self.dockTileRow, screen: Self.screen)

        (1...3600).forEach { field.advance(to: Float($0) * Self.frameDuration) }

        let pile: SnowDrift = try #require(field.drifts[.window(3)])
        let dock: SnowDrift = try #require(field.drifts[.dock])
        #expect(!pile.occluders.isEmpty)
        #expect(pile.heights.suffix(80).allSatisfy { $0 == 0 })
        #expect(pile.heights.prefix(36).contains { $0 > 0 })
        #expect(dock.occluders.isEmpty)
        #expect(dock.volume > 0)
    }
}
