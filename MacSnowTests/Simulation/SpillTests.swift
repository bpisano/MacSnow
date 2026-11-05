//
//  SpillTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct SpillTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let tolerance: Float = 0.001
    private static let ledge: SnowSurface = .mock(id: .window(7), frame: .init(x: 100, y: 200, width: 400, height: 300), zIndex: 1)
    private static let leftHalf: SnowSurface = .mock(id: .window(3), frame: .init(x: 0, y: 0, width: 300, height: 600), zIndex: 0)

    private static func snowyField() -> SnowField {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [ledge]
        (1...1800).forEach { field.advance(to: Float($0) * frameDuration) }
        return field
    }

    private static func area(of grains: [Grain]) -> Float {
        grains.map(\.area).reduce(0, +)
    }

    /// Feeds `drift` snow every frame for `seconds`, its clock running.
    /// - Returns: When chunks broke off each end, in seconds.
    private static func breaks(feeding drift: inout SnowDrift, for seconds: Float) -> (left: [Float], right: [Float]) {
        let frames: Int = .init(seconds / frameDuration)
        let chunks: [(time: Float, spill: Spill)] = (1...frames).flatMap { frame in
            let time: Float = .init(frame) * frameDuration
            _ = drift.sway(to: time, for: frameDuration)
            return drift.deposit(6, at: 100 + Float(frame % 400)).map { (time, $0) }
        }
        let left: Float = drift.left
        return (
            chunks.filter { $0.spill.position.x < left }.map(\.time),
            chunks.filter { $0.spill.position.x >= left }.map(\.time)
        )
    }

    @Test
    func `snow past capacity breaks off the nearest end in chunks, none lost when the ends rest enough`() {
        var drift: SnowDrift = .init(on: Self.ledge)

        let spills: [Spill] = (0..<4000).flatMap { index in
            _ = drift.sway(to: Float(index) * 60, for: Self.frameDuration)
            return drift.deposit(6, at: 100 + Float(index % 400))
        }

        let spilled: Float = spills.map(\.area).reduce(0, +)
        #expect(spilled > 0)
        #expect(spills.allSatisfy { $0.area > SnowField.clumpArea })
        #expect(Set(spills.map(\.area)).count > 1)
        #expect(abs(drift.volume + spilled - 24_000) < 24_000 * Self.tolerance)
        #expect(spills.allSatisfy { $0.position.x < drift.left || $0.position.x > drift.right })
        #expect(zip(drift.heights, drift.capacity).allSatisfy { $0 <= $1 })
        #expect(drift.heights[100] == SnowDrift.deepest)
    }

    @Test
    func `an end rests at least fifteen seconds after a chunk breaks off`() {
        var drift: SnowDrift = .init(on: Self.ledge)

        let breaks: (left: [Float], right: [Float]) = Self.breaks(feeding: &drift, for: 60)

        for times in [breaks.left, breaks.right] {
            #expect(!times.isEmpty)
            #expect(times.count <= 5)
            #expect(zip(times, times.dropFirst()).allSatisfy { $1 - $0 >= 15 })
        }
    }

    @Test
    func `an end breaks off again once rested, the snow overflowing meanwhile melting`() {
        var drift: SnowDrift = .init(on: Self.ledge)
        let held: Float = drift.capacity.reduce(0, +) * SnowDrift.columnWidth + 2 * 48

        let breaks: (left: [Float], right: [Float]) = Self.breaks(feeding: &drift, for: 150)

        #expect(breaks.left.count >= 2)
        #expect(breaks.right.count >= 2)
        #expect(drift.volume <= held)
    }

    @Test
    func `a spill crumbles into pieces sharing its area`() {
        let spill: Spill = .init(position: .init(10, 20), area: 40)

        let pieces: [Spill] = spill.crumbled(into: [1, 3])

        #expect(pieces.map(\.area) == [10, 30])
        #expect(pieces.allSatisfy { $0.position == spill.position })
    }

    @Test
    func `spills larger than a clump fall as grains of mixed sizes`() throws {
        var field: SnowField = Self.snowyField()
        let piled: Float = try #require(field.drifts[.window(7)]).volume
        let falling: Int = field.grains.count

        field.clear()

        let released: [Grain] = .init(field.grains.dropFirst(falling))
        let clumps: Int = .init((piled / SnowField.clumpArea).rounded(.up))
        #expect(released.count > clumps)
        #expect(Set(released.map(\.area)).count > released.count / 2)
        #expect(abs(Self.area(of: released) - piled) < piled * Self.tolerance)
    }

    @Test
    func `snow covered by a window in front falls as grains`() throws {
        var field: SnowField = Self.snowyField()
        let piled: Float = try #require(field.drifts[.window(7)]).volume
        let falling: Int = field.grains.count

        field.surfaces = [Self.leftHalf, Self.ledge]

        let drift: SnowDrift = try #require(field.drifts[.window(7)])
        let released: [Grain] = .init(field.grains.dropFirst(falling))
        #expect(!released.isEmpty)
        #expect(abs(Self.area(of: released) - (piled - drift.volume)) < piled * Self.tolerance)
        #expect(released.allSatisfy { $0.position.x >= 90 && $0.position.x <= 310 })
    }
}
