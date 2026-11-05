//
//  WindowRecordTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
import Foundation
@testable import MacSnow
import Testing

@Suite
struct WindowRecordTests {
    private static var recordedInfo: [String: Any] {
        [
            kCGWindowNumber as String: NSNumber(value: 4242),
            kCGWindowOwnerPID as String: NSNumber(value: 812),
            kCGWindowOwnerName as String: "Safari",
            kCGWindowLayer as String: NSNumber(value: 0),
            kCGWindowAlpha as String: NSNumber(value: 1.0),
            kCGWindowBounds as String: CGRect(x: 120, y: 38, width: 1280, height: 800).dictionaryRepresentation,
            kCGWindowStoreType as String: NSNumber(value: 1),
            kCGWindowIsOnscreen as String: NSNumber(value: true)
        ]
    }

    @Test
    func `reads a recorded window dictionary`() throws {
        let record: WindowRecord = try #require(WindowRecord(info: Self.recordedInfo))

        #expect(
            record == .init(
                number: 4242,
                ownerPID: 812,
                layer: 0,
                alpha: 1,
                bounds: .init(x: 120, y: 38, width: 1280, height: 800)
            )
        )
    }

    @Test
    func `skips a dictionary without bounds`() {
        var info: [String: Any] = Self.recordedInfo
        info[kCGWindowBounds as String] = nil

        #expect(WindowRecord(info: info) == nil)
    }
}
