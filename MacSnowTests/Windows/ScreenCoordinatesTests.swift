//
//  ScreenCoordinatesTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct ScreenCoordinatesTests {
    private let coordinates: ScreenCoordinates = .init(primaryScreenMaxY: 900)

    @Test
    func `flips a window on the primary screen`() {
        let frame: CGRect = coordinates.cocoaFrame(fromCoreGraphics: .init(x: 100, y: 50, width: 400, height: 300))

        #expect(frame == .init(x: 100, y: 550, width: 400, height: 300))
    }

    @Test
    func `window at the top of the primary screen touches its top edge`() {
        let frame: CGRect = coordinates.cocoaFrame(fromCoreGraphics: .init(x: 0, y: 0, width: 400, height: 300))

        #expect(frame.maxY == 900)
    }

    @Test
    func `flips a window on a secondary screen above`() {
        let frame: CGRect = coordinates.cocoaFrame(fromCoreGraphics: .init(x: 100, y: -1000, width: 400, height: 300))

        #expect(frame == .init(x: 100, y: 1600, width: 400, height: 300))
    }

    @Test
    func `flips a window on a secondary screen to the left`() {
        let frame: CGRect = coordinates.cocoaFrame(fromCoreGraphics: .init(x: -1800, y: -100, width: 400, height: 300))

        #expect(frame == .init(x: -1800, y: 700, width: 400, height: 300))
    }
}
