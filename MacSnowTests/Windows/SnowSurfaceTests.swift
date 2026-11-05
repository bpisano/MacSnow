//
//  SnowSurfaceTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct SnowSurfaceTests {
    private static let screen: CGRect = .init(x: 0, y: 0, width: 1440, height: 900)

    @Test
    func `ranks the Dock in front of every window and the ground behind them`() {
        let windows: [SnowSurface] = [.mock(id: .window(4), zIndex: 0), .mock(id: .window(2), zIndex: 1)]

        let surfaces: [SnowSurface] = SnowSurface.frontToBack(
            windows: windows,
            dockTileRow: .init(x: 400, y: 4, width: 640, height: 70),
            screen: Self.screen
        )

        #expect(surfaces.map(\.id) == [.dock, .window(4), .window(2), .ground])
        #expect(surfaces.map(\.zIndex) == [0, 1, 2, 3])
    }

    @Test
    func `the ground spans the screen bottom`() throws {
        let surfaces: [SnowSurface] = SnowSurface.frontToBack(windows: [], dockTileRow: nil, screen: Self.screen)

        let ground: SnowSurface = try #require(surfaces.first)
        #expect(surfaces.count == 1)
        #expect(ground.id == .ground)
        #expect(ground.frame == .init(x: 0, y: 0, width: 1440, height: 0))
        #expect(ground.cornerRadius == 0)
    }

    @Test
    func `a window whose top spans two screens is a ledge on both`() {
        let side: CGRect = .init(x: 1440, y: 0, width: 1920, height: 1080)
        let window: SnowSurface = .mock(frame: .init(x: 1000, y: 300, width: 900, height: 500))

        let main: [SnowSurface] = SnowSurface.frontToBack(windows: [window], dockTileRow: nil, screen: Self.screen)
        let beside: [SnowSurface] = SnowSurface.frontToBack(windows: [window], dockTileRow: nil, screen: side)

        #expect(main.map(\.id) == [.window(1), .ground])
        #expect(beside.map(\.id) == [.window(1), .ground])
    }

    @Test
    func `a window is a ledge only on the screen holding its top edge`() {
        let above: CGRect = .init(x: 0, y: 900, width: 1440, height: 900)
        let reaching: SnowSurface = .mock(id: .window(3), frame: .init(x: 200, y: 600, width: 800, height: 700))
        let below: SnowSurface = .mock(id: .window(5), frame: .init(x: 200, y: 100, width: 800, height: 400))

        let main: [SnowSurface] = SnowSurface.frontToBack(windows: [reaching, below], dockTileRow: nil, screen: Self.screen)
        let upper: [SnowSurface] = SnowSurface.frontToBack(windows: [reaching, below], dockTileRow: nil, screen: above)

        #expect(main.map(\.id) == [.window(5), .ground])
        #expect(main.map(\.zIndex) == [0, 1])
        #expect(upper.map(\.id) == [.window(3), .ground])
    }

    @Test
    func `the Dock is a ledge only on the screen it sits on`() {
        let side: CGRect = .init(x: 1440, y: 0, width: 1920, height: 1080)
        let tileRow: CGRect = .init(x: 400, y: 4, width: 640, height: 70)

        let main: [SnowSurface] = SnowSurface.frontToBack(windows: [], dockTileRow: tileRow, screen: Self.screen)
        let beside: [SnowSurface] = SnowSurface.frontToBack(windows: [], dockTileRow: tileRow, screen: side)

        #expect(main.map(\.id) == [.dock, .ground])
        #expect(beside.map(\.id) == [.ground])
    }

    @Test
    func `each screen's ground is its own bottom edge`() throws {
        let side: CGRect = .init(x: 1440, y: -180, width: 1920, height: 1080)

        let ground: SnowSurface = try #require(SnowSurface.frontToBack(windows: [], dockTileRow: nil, screen: side).first)

        #expect(ground.frame == .init(x: 1440, y: -180, width: 1920, height: 0))
    }
}
