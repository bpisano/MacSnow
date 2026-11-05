//
//  RecordingOverlayFactory.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow

final class RecordingOverlayFactory: OverlayFactory {
    let events: AsyncStream<RecordingOverlay.Event>

    private(set) var overlays: [CGDirectDisplayID: RecordingOverlay] = [:]
    private(set) var coveredDisplays: [CGDirectDisplayID] = []

    private let continuation: AsyncStream<RecordingOverlay.Event>.Continuation

    init() {
        (events, continuation) = AsyncStream.makeStream()
    }

    func makeOverlay(covering screen: SnowScreen) -> any Overlay {
        let overlay: RecordingOverlay = .init(display: screen.id, events: continuation)
        overlays[screen.id] = overlay
        coveredDisplays.append(screen.id)
        return overlay
    }
}
