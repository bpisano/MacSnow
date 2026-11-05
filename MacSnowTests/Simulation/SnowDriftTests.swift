//
//  SnowDriftTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct SnowDriftTests {
    private static let tolerance: Float = 0.01
    private static let frameDuration: Float = 1.0 / 60.0

    private let drift: SnowDrift = .init(on: .mock(frame: .init(x: 100, y: 200, width: 400, height: 300), cornerRadius: 10))

    private static func peak(of drift: SnowDrift) throws -> Float {
        let column: Int = try #require(drift.heights.indices.max { drift.heights[$0] < drift.heights[$1] })
        return drift.left + (Float(column) + 0.5) * SnowDrift.columnWidth
    }

    @Test
    func `rests on the window top edge`() {
        #expect(drift.left == 100)
        #expect(drift.top == 500)
        #expect(drift.heights.count == 160)
        #expect(drift.volume == 0)
    }

    @Test
    func `holds no snow over the rounded corners`() {
        let corners: [Float] = drift.capacity.prefix(4) + drift.capacity.suffix(4)

        #expect(corners.allSatisfy { $0 == 0 })
    }

    @Test
    func `capacity ramps up to the deepest past the corners`() {
        let ramp: [Float] = .init(drift.capacity.prefix(20))
        let rampEnd: Int = .init((10 + SnowDrift.ramp) / SnowDrift.columnWidth)

        #expect(zip(ramp, ramp.dropFirst()).allSatisfy { $0 <= $1 })
        #expect(drift.capacity[rampEnd] == SnowDrift.deepest)
        #expect(drift.capacity[100] == SnowDrift.deepest)
        #expect(drift.capacity == drift.capacity.reversed())
    }

    @Test
    func `a filling column takes less of a flake's snow, none once full`() {
        var filling: SnowDrift = drift
        let bare: Float = filling.room(at: 300)

        _ = filling.deposit(8, at: 300)
        let piled: Float = filling.room(at: 300)
        (0..<400).forEach { _ in _ = filling.deposit(8, at: 300) }

        #expect(bare == 1)
        #expect(piled > 0 && piled < 1)
        #expect(filling.room(at: 300) == 0)
        #expect(filling.room(at: 101) == 0)
    }

    @Test
    func `scattered snow piles into a smooth surface, no spikes`() {
        var pile: SnowDrift = drift
        var seed: UInt32 = 12_345
        (0..<600).forEach { _ in
            seed = seed &* 1_664_525 &+ 1_013_904_223
            _ = pile.deposit(6, at: 130 + Float(seed >> 8) / Float(1 << 24) * 340)
        }

        let bends: [Float] = (16..<144).map { column in
            abs(pile.heights[column] - (pile.heights[column - 1] + pile.heights[column + 1]) / 2)
        }
        let roughest: Float = bends.max() ?? 0
        #expect(roughest < 0.25)
    }

    @Test
    func `a deposit keeps its volume away from the ends`() {
        var drift: SnowDrift = self.drift

        _ = drift.deposit(8, at: 300)

        #expect(abs(drift.volume - 8) < Self.tolerance)
        #expect(drift.height(at: 301) > 0)
    }

    @Test
    func `slumping keeps the volume and the angle of repose`() {
        var drift: SnowDrift = self.drift

        (0..<20).forEach { _ in _ = drift.deposit(6, at: 300) }

        let steepest: Float = DriftShape.repose * SnowDrift.columnWidth
        #expect(abs(drift.volume - 120) < Self.tolerance)
        #expect(zip(drift.heights, drift.heights.dropFirst()).allSatisfy { abs($0 - $1) <= steepest + Self.tolerance })
        #expect(drift.peak <= SnowDrift.deepest)
    }

    @Test
    func `moving the window carries the snow`() {
        var drift: SnowDrift = self.drift
        _ = drift.deposit(8, at: 300)
        let heights: [Float] = drift.heights

        let spills: [Spill] = drift.move(onto: .mock(frame: .init(x: 400, y: 50, width: 400, height: 300), cornerRadius: 10))

        #expect(spills.isEmpty)
        #expect(drift.heights == heights)
        #expect(drift.left == 400)
        #expect(drift.top == 350)
        #expect(drift.height(at: 651.25) == heights[100])
    }

    @Test
    func `shrinking from the right drops the cut columns past the new edge`() {
        var drift: SnowDrift = self.drift
        (0..<10).forEach { _ in _ = drift.deposit(8, at: 450) }
        let piled: Float = drift.volume
        let heights: [Float] = drift.heights

        let spills: [Spill] = drift.move(onto: .mock(frame: .init(x: 100, y: 200, width: 300, height: 300), cornerRadius: 10))

        #expect(heights.suffix(40).contains { $0 > 0 })
        #expect(drift.heights.count == 120)
        #expect(drift.heights == Array(heights.prefix(120)))
        #expect(!spills.isEmpty)
        #expect(spills.allSatisfy { $0.position.x > 400 })
        #expect(abs(drift.volume + spills.reduce(0) { $0 + $1.area } - piled) < Self.tolerance)
    }

    @Test
    func `shrinking from the left keeps the snow where it lies and drops the left columns`() {
        var drift: SnowDrift = self.drift
        (0..<10).forEach { _ in _ = drift.deposit(8, at: 140) }
        let piled: Float = drift.volume
        let heights: [Float] = drift.heights

        let spills: [Spill] = drift.move(onto: .mock(frame: .init(x: 150, y: 200, width: 350, height: 300), cornerRadius: 10))

        #expect(heights.prefix(20).contains { $0 > 0 })
        #expect(drift.heights.count == 140)
        #expect(Array(drift.heights[15..<60]) == Array(heights[35..<80]))
        #expect(drift.height(at: 188.75) == heights[35])
        #expect(spills.contains { $0.position.x < 150 })
        #expect(abs(drift.volume + spills.reduce(0) { $0 + $1.area } - piled) < Self.tolerance)
    }

    @Test
    func `snow too deep for the new corners spills from its kept surface`() {
        var drift: SnowDrift = self.drift
        (0..<40).forEach { _ in _ = drift.deposit(8, at: 300) }
        let piled: Float = drift.volume

        let spills: [Spill] = drift.move(onto: .mock(frame: .init(x: 100, y: 200, width: 400, height: 300), cornerRadius: 190))

        #expect(zip(drift.heights, drift.capacity).allSatisfy { $0 <= $1 })
        #expect(!spills.isEmpty)
        #expect(spills.allSatisfy { $0.position.x > 100 && $0.position.x < 500 })
        #expect(abs(drift.volume + spills.reduce(0) { $0 + $1.area } - piled) < Self.tolerance)
    }

    @Test
    func `a path crossing the ledge lands at the crossing time`() throws {
        let path: (Float) -> SIMD2<Float> = { .init(300, 600 - 50 * $0) }

        let time: Float = try #require(Landing.crossing(of: path, from: 0, to: 10, on: drift))

        #expect(abs(time - 2) < Self.tolerance)
    }

    @Test
    func `a path lands on the snow before the ledge`() throws {
        var drift: SnowDrift = self.drift
        (0..<10).forEach { _ in _ = drift.deposit(8, at: 300) }
        let surface: Float = drift.height(at: 300)
        let path: (Float) -> SIMD2<Float> = { .init(300, 600 - 50 * $0) }

        let time: Float = try #require(Landing.crossing(of: path, from: 0, to: 10, on: drift))

        #expect(surface > 1)
        #expect(abs(time - (2 - surface / 50)) < Self.tolerance)
    }

    @Test
    func `a path beside the ledge does not land`() {
        let path: (Float) -> SIMD2<Float> = { .init(520, 600 - 50 * $0) }

        #expect(Landing.crossing(of: path, from: 0, to: 10, on: drift) == nil)
    }

    @Test
    func `a path starting under the ledge does not land`() {
        let path: (Float) -> SIMD2<Float> = { .init(300, 450 - 50 * $0) }

        #expect(Landing.crossing(of: path, from: 0, to: 2, on: drift) == nil)
    }

    @Test
    func `a slow drag of the left edge keeps the pile where it lies on screen`() throws {
        var drift: SnowDrift = self.drift
        _ = drift.deposit(40, at: 300)
        let peak: Float = try Self.peak(of: drift)

        (1...40).forEach { step in
            let widening: CGFloat = 0.5 * CGFloat(step)
            drift.move(onto: .mock(frame: .init(x: 100 - widening, y: 200, width: 400 + widening, height: 300), cornerRadius: 10))
        }

        #expect(drift.left == 80)
        #expect(abs(try Self.peak(of: drift) - peak) <= SnowDrift.columnWidth)
    }

    @Test
    func `resizing a ledge leaves its pile still`() {
        var drift: SnowDrift = self.drift

        drift.move(onto: .mock(frame: .init(x: 60, y: 200, width: 440, height: 300), cornerRadius: 10))
        let shakes: [Shake] = drift.sway(to: Self.frameDuration, for: Self.frameDuration)

        #expect(drift.offset == 0)
        #expect(shakes.isEmpty)
    }

    @Test
    func `moving a ledge leaves its pile behind`() {
        var drift: SnowDrift = self.drift

        drift.move(onto: .mock(frame: .init(x: 103, y: 200, width: 400, height: 300), cornerRadius: 10))

        #expect(drift.offset == -3)
    }
}
