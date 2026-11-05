//
//  ClockTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

@testable import MacSnow
import Testing

@Suite
struct ClockTests {
    private static let tolerance: Float = 0.05

    private static func distance(from first: SIMD2<Float>, to second: SIMD2<Float>, width: Float) -> Float {
        let span: Float = width + 2 * SnowField.margin
        let across: Float = abs(first.x - second.x)
        return max(min(across, span - across), abs(first.y - second.y))
    }

    @Test
    func `moving the clock back keeps every flake where it was`() {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.advance(to: SnowField.clockSpan - 0.05)
        let before: SnowField = field
        let time: Float = SnowField.clockSpan + 0.01

        field.advance(to: time)

        let blown: Float = before.wind.offset + field.wind.speed * 0.06
        let kept: [SnowFlake] = before.flakes.filter { $0.gone > time }
        let moved: [Float] = zip(kept, field.flakes).map { flake, rewound in
            Self.distance(
                from: flake.position(at: time, wind: blown, width: field.width),
                to: field.position(of: rewound, at: field.now),
                width: field.width
            )
        }
        #expect(field.epoch == Double(SnowField.clockSpan))
        #expect(abs(field.now - 0.01) < 0.001)
        #expect(field.wind.offset == 0)
        #expect(!kept.isEmpty)
        #expect(moved.allSatisfy { $0 < Self.tolerance })
    }

    @Test
    func `flakes born again after a long pause spread above the screen`() {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.advance(to: 1)

        field.advance(to: 600)

        let tops: [Float] = field.flakes.map(\.top)
        #expect(field.flakes.allSatisfy { $0.born == 600 })
        #expect(tops.allSatisfy { $0 >= field.height })
        #expect((tops.max() ?? 0) - (tops.min() ?? 0) > field.height / 2)
    }
}
