//
//  DockWatchTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@MainActor
@Suite
struct DockWatchTests {
    private static let primaryScreen: CGRect = .init(x: 0, y: 0, width: 2560, height: 1440)
    private static let shownDock: CGRect = .init(x: 543, y: 1350, width: 1474, height: 84)

    private let reader: FakeDockReader = .init()
    private let watch: DockWatch

    init() {
        watch = .init(reader: reader, screenFrames: { [Self.primaryScreen] })
    }

    @Test
    func `converts the tile row from Accessibility coordinates to Cocoa coordinates`() {
        reader.frame = Self.shownDock

        watch.read()

        #expect(watch.tileRow == .init(x: 543, y: 6, width: 1474, height: 84))
    }

    @Test
    func `a Dock on a side has no tile row`() {
        reader.frame = .init(x: 0, y: 400, width: 84, height: 640)

        watch.read()

        #expect(watch.tileRow == nil)
    }

    @Test
    func `a hidden Dock off the screen bottom has no tile row`() {
        reader.frame = .init(x: 543, y: 1440, width: 1474, height: 84)

        watch.read()

        #expect(watch.tileRow == nil)
    }

    @Test
    func `an unreadable Dock has no tile row`() {
        reader.frame = Self.shownDock
        watch.read()

        reader.frame = nil
        watch.read()

        #expect(watch.tileRow == nil)
    }

    @Test
    func `a Dock along a secondary screen bottom has a tile row`() {
        let secondaryScreen: CGRect = .init(x: 2560, y: -451, width: 1920, height: 1080)
        let watch: DockWatch = .init(reader: reader, screenFrames: { [Self.primaryScreen, secondaryScreen] })
        reader.frame = .init(x: 3000, y: 1800, width: 1000, height: 80)

        watch.read()

        #expect(watch.tileRow == .init(x: 3000, y: -440, width: 1000, height: 80))
    }

    @Test
    func `reads on start and forgets the tile row on stop`() {
        reader.frame = Self.shownDock

        watch.start()
        let started: CGRect? = watch.tileRow
        watch.stop()

        #expect(started != nil)
        #expect(watch.tileRow == nil)
        #expect(!watch.isWatching)
    }
}
