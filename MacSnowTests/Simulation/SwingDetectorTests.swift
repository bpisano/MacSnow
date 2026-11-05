//
//  SwingDetectorTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

@testable import MacSnow
import Testing

@Suite
struct SwingDetectorTests {
    private static func track(_ samples: [(velocity: Float, time: Float)]) -> [Int?] {
        var detector: SwingDetector = .init()
        return samples.map { detector.track($0.velocity, at: $0.time) }
    }

    @Test
    func `the third fast reversal makes a shake`() {
        let shakes: [Int?] = Self.track([(400, 0), (-400, 0.15), (400, 0.3), (-400, 0.45), (400, 0.6)])

        #expect(shakes == [nil, nil, nil, 3, 4])
    }

    @Test
    func `slow reversals are no shake`() {
        let shakes: [Int?] = Self.track([(150, 0), (-150, 0.15), (150, 0.3), (-150, 0.45), (150, 0.6)])

        #expect(shakes.allSatisfy { $0 == nil })
    }

    @Test
    func `reversals spread past the memory are no shake`() {
        let shakes: [Int?] = Self.track([(400, 0), (-400, 0.6), (400, 1.2), (-400, 1.8), (400, 2.4)])

        #expect(shakes.allSatisfy { $0 == nil })
    }

    @Test
    func `a fast drag one way is no reversal`() {
        let shakes: [Int?] = Self.track([(400, 0), (900, 0.1), (100, 0.2), (600, 0.3), (2000, 0.4)])

        #expect(shakes.allSatisfy { $0 == nil })
    }
}
