//
//  OverlayControllerTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@MainActor
@Suite
struct OverlayControllerTests {
    private static let main: SnowScreen = .mock(id: 1)
    private static let side: SnowScreen = .mock(id: 2, frame: .init(x: 1440, y: 0, width: 1920, height: 1080))

    private let store: SnowStore = .init(preferences: InMemorySnowPreferences(isSnowing: true))
    private let factory: RecordingOverlayFactory = .init()
    private let tracker: RecordingSurfaceTracker = .init()
    private let screenWatch: FakeScreenWatch = .init([Self.main])
    private let controller: OverlayController

    init() {
        controller = .init(store: store, factory: factory, screenWatch: screenWatch, trackers: [tracker])
    }

    @Test
    func `shows the overlay when snow is falling at launch`() async {
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()

        #expect(await events.next() == .shown(1))
    }

    @Test
    func `closes the overlay once the last flake fell out`() async throws {
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()
        #expect(await events.next() == .shown(1))

        store.isSnowing = false
        #expect(await events.next() == .stoppedSnowing(1))

        try #require(factory.overlays[1]).letLastFlakeFallOut()
        #expect(await events.next() == .closed(1))

        store.isSnowing = true
        #expect(await events.next() == .shown(1))
    }

    @Test
    func `keeps the overlay when snow starts again before the last flake fell out`() async throws {
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()
        #expect(await events.next() == .shown(1))
        let overlay: RecordingOverlay = try #require(factory.overlays[1])

        store.isSnowing = false
        #expect(await events.next() == .stoppedSnowing(1))

        store.isSnowing = true
        #expect(await events.next() == .startedSnowing(1))

        store.isSnowing = false
        #expect(await events.next() == .stoppedSnowing(1))

        overlay.letLastFlakeFallOut()
        #expect(await events.next() == .closed(1))
        #expect(factory.coveredDisplays == [1])
    }

    @Test
    func `clears the overlay's snow while snow is falling`() async {
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()
        #expect(await events.next() == .shown(1))

        store.clear()

        #expect(await events.next() == .clearedSnow(1))
    }

    @Test
    func `ignores clearing once snow stopped`() async throws {
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()
        #expect(await events.next() == .shown(1))

        store.isSnowing = false
        #expect(await events.next() == .stoppedSnowing(1))

        store.clear()
        try #require(factory.overlays[1]).letLastFlakeFallOut()
        #expect(await events.next() == .closed(1))

        store.isSnowing = true
        #expect(await events.next() == .shown(1))
    }

    @Test
    func `shows an overlay on every screen`() async {
        screenWatch.change(to: [Self.main, Self.side])
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()

        #expect(await events.next() == .shown(1))
        #expect(await events.next() == .shown(2))
    }

    @Test
    func `covers a plugged screen and keeps the others`() async {
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()
        #expect(await events.next() == .shown(1))

        screenWatch.change(to: [Self.main, Self.side])

        #expect(await events.next() == .shown(2))
        #expect(factory.coveredDisplays == [1, 2])
    }

    @Test
    func `closes the overlay of an unplugged screen and keeps the others`() async {
        screenWatch.change(to: [Self.main, Self.side])
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()
        #expect(await events.next() == .shown(1))
        #expect(await events.next() == .shown(2))

        screenWatch.change(to: [Self.side])
        #expect(await events.next() == .closed(1))

        store.clear()
        #expect(await events.next() == .clearedSnow(2))
        #expect(factory.coveredDisplays == [1, 2])
    }

    @Test
    func `covers a screen again once its frame changed`() async {
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()
        #expect(await events.next() == .shown(1))

        screenWatch.change(to: [.mock(id: 1, frame: .init(x: 0, y: 0, width: 1920, height: 1080))])

        #expect(await events.next() == .closed(1))
        #expect(await events.next() == .shown(1))
    }

    @Test
    func `closes every overlay once the last flake fell out on every screen`() async throws {
        screenWatch.change(to: [Self.main, Self.side])
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()
        #expect(await events.next() == .shown(1))
        #expect(await events.next() == .shown(2))

        store.isSnowing = false
        let stopped: Set<RecordingOverlay.Event?> = [await events.next(), await events.next()]
        #expect(stopped == [.stoppedSnowing(1), .stoppedSnowing(2)])

        try #require(factory.overlays[1]).letLastFlakeFallOut()
        try #require(factory.overlays[2]).letLastFlakeFallOut()
        #expect(await events.next() == .closed(1))
        #expect(await events.next() == .closed(2))
    }

    @Test
    func `tracks the ledges once while any overlay shows`() async throws {
        screenWatch.change(to: [Self.main, Self.side])
        let running: Task<Void, Never> = .init { await controller.run() }
        defer { running.cancel() }
        var events: AsyncStream<RecordingOverlay.Event>.Iterator = factory.events.makeAsyncIterator()
        #expect(await events.next() == .shown(1))
        #expect(await events.next() == .shown(2))

        screenWatch.change(to: [Self.side])
        #expect(await events.next() == .closed(1))
        #expect(tracker.starts == 1)
        #expect(tracker.stops == 0)

        store.isSnowing = false
        #expect(await events.next() == .stoppedSnowing(2))
        try #require(factory.overlays[2]).letLastFlakeFallOut()
        #expect(await events.next() == .closed(2))
        #expect(tracker.stops == 1)
    }
}
