//
//  WindowTrackerTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@MainActor
@Suite
struct WindowTrackerTests {
    private static let ownPID: pid_t = 42
    private static let primaryScreenMaxY: CGFloat = 900

    private let listing: FakeWindowListing = .init()
    private let tracker: WindowTracker

    init() {
        tracker = .init(listing: listing, ownPID: Self.ownPID, primaryScreenMaxY: { Self.primaryScreenMaxY })
    }

    @Test
    func `lists app windows front to back in Cocoa coordinates`() {
        listing.records = [
            .mock(number: 7, ownerPID: 100, bounds: .init(x: 100, y: 50, width: 400, height: 300)),
            .mock(number: 3, ownerPID: 200, bounds: .init(x: 0, y: 0, width: 1440, height: 875))
        ]

        tracker.poll()

        #expect(
            tracker.surfaces == [
                .mock(id: .window(7), frame: .init(x: 100, y: 550, width: 400, height: 300), zIndex: 0),
                .mock(id: .window(3), frame: .init(x: 0, y: 25, width: 1440, height: 875), zIndex: 1)
            ]
        )
    }

    @Test
    func `never lists own overlay, menu bar, Dock or desktop`() {
        listing.records = [
            .mock(number: 1, ownerPID: Self.ownPID, layer: 25, bounds: .init(x: 0, y: 0, width: 1440, height: 900)),
            .mock(number: 2, ownerPID: Self.ownPID, layer: 0),
            .mock(number: 3, ownerPID: 300, layer: 24, bounds: .init(x: 0, y: 0, width: 1440, height: 25)),
            .mock(number: 4, ownerPID: 400, layer: 20, bounds: .init(x: 400, y: 820, width: 640, height: 80)),
            .mock(number: 5, ownerPID: 400, layer: -2_147_483_603, bounds: .init(x: 0, y: 0, width: 1440, height: 900)),
            .mock(number: 6, ownerPID: 100)
        ]

        tracker.poll()

        #expect(tracker.surfaces.map(\.id) == [.window(6)])
    }

    @Test
    func `skips transparent and tiny windows`() {
        listing.records = [
            .mock(number: 1, alpha: 0),
            .mock(number: 2, bounds: .init(x: 0, y: 0, width: 39, height: 300)),
            .mock(number: 3, bounds: .init(x: 0, y: 0, width: 300, height: 39)),
            .mock(number: 4, bounds: .init(x: 0, y: 0, width: 40, height: 40))
        ]

        tracker.poll()

        #expect(tracker.surfaces.map(\.id) == [.window(4)])
    }

    @Test
    func `z-index counts listed surfaces only`() {
        listing.records = [
            .mock(number: 1, layer: 24),
            .mock(number: 2),
            .mock(number: 3)
        ]

        tracker.poll()

        #expect(tracker.surfaces.map(\.zIndex) == [0, 1])
    }

    @Test
    func `start polls right away`() {
        listing.records = [.mock(number: 1)]

        tracker.start()
        defer { tracker.stop() }

        #expect(tracker.isTracking)
        #expect(tracker.surfaces.map(\.id) == [.window(1)])
    }

    @Test(.timeLimit(.minutes(1)))
    func `timer polls on its own`() async throws {
        listing.records = [.mock(number: 1)]
        tracker.start()
        defer { tracker.stop() }

        listing.records = []
        while !tracker.surfaces.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(tracker.surfaces.isEmpty)
    }

    @Test
    func `stop invalidates the timer and forgets surfaces`() {
        listing.records = [.mock(number: 1)]
        tracker.start()

        tracker.stop()

        #expect(!tracker.isTracking)
        #expect(tracker.surfaces.isEmpty)
    }
}
