//
//  RecordingOverlay.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow

final class RecordingOverlay: Overlay {
    enum Event: Hashable {
        case shown(CGDirectDisplayID)
        case startedSnowing(CGDirectDisplayID)
        case stoppedSnowing(CGDirectDisplayID)
        case clearedSnow(CGDirectDisplayID)
        case closed(CGDirectDisplayID)
    }

    private let display: CGDirectDisplayID
    private let events: AsyncStream<Event>.Continuation
    private var fallingOut: AsyncStream<Void>.Continuation?

    init(display: CGDirectDisplayID, events: AsyncStream<Event>.Continuation) {
        self.display = display
        self.events = events
    }

    func show() {
        events.yield(.shown(display))
    }

    func startSnowing() {
        events.yield(.startedSnowing(display))
    }

    func stopSnowing() async {
        let (fellOut, continuation): (AsyncStream<Void>, AsyncStream<Void>.Continuation) = AsyncStream.makeStream()
        fallingOut = continuation
        events.yield(.stoppedSnowing(display))
        for await _ in fellOut {
            break
        }
    }

    func clearSnow() {
        events.yield(.clearedSnow(display))
    }

    func close() {
        events.yield(.closed(display))
    }

    func letLastFlakeFallOut() {
        fallingOut?.yield()
    }
}
