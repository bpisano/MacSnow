//
//  CursorSweepTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct CursorSweepTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let tolerance: Float = 0.001
    private static let ledge: SnowSurface = .mock(id: .window(7), frame: .init(x: 100, y: 200, width: 400, height: 300), zIndex: 1)
    private static let brushed: ClosedRange<Int> = 58...77
    private static let nearBrush: ClosedRange<Int> = 38...97

    private static func snowyDrift() -> SnowDrift {
        var drift: SnowDrift = .init(on: ledge)
        (0..<4000).forEach { index in _ = drift.deposit(6, at: 100 + Float(index % 400)) }
        return drift
    }

    private static func snowyField() -> SnowField {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [ledge]
        (1...1800).forEach { field.advance(to: Float($0) * frameDuration) }
        return field
    }

    private static func pass(at height: Float) -> Sweep? {
        .init(from: .init(250, height), to: .init(290, height), over: frameDuration)
    }

    @Test
    func `a fast pass sweeps snow only under the brush, even across a whole frame`() throws {
        var drift: SnowDrift = Self.snowyDrift()
        let piled: [Float] = drift.heights
        let volume: Float = drift.volume

        let spills: [Spill] = drift.sweep(try #require(Self.pass(at: 505)))

        let swept: [Int] = drift.heights.indices.filter { drift.heights[$0] != piled[$0] }
        let steepest: Float = DriftShape.repose * SnowDrift.columnWidth
        #expect(swept.allSatisfy { Self.nearBrush.contains($0) })
        #expect(drift.heights[67] < 0.6 * piled[67])
        #expect(Self.nearBrush.dropLast().allSatisfy { abs(drift.heights[$0] - drift.heights[$0 + 1]) <= steepest * 1.05 })
        #expect(spills.count == Self.brushed.count)
        #expect(abs(spills.map(\.area).reduce(0, +) + drift.volume - volume) < Self.tolerance)
    }

    @Test
    func `a slow hover leaves the pile`() throws {
        var field: SnowField = Self.snowyField()
        let piled: [Float] = try #require(field.drifts[.window(7)]).heights

        field.movePointer(to: .init(250, 505))
        field.advance(to: field.now + Self.frameDuration)
        field.movePointer(to: .init(251, 505))

        let drift: SnowDrift = try #require(field.drifts[.window(7)])
        #expect(Sweep(from: .init(250, 505), to: .init(251, 505), over: Self.frameDuration) == nil)
        #expect(Self.brushed.allSatisfy { drift.heights[$0] >= 0.9 * piled[$0] })
    }

    @Test
    func `the first pointer sample sweeps nothing`() throws {
        var field: SnowField = Self.snowyField()
        let piled: Float = try #require(field.drifts[.window(7)]).volume
        let falling: Int = field.grains.count

        field.movePointer(to: .init(250, 505))

        #expect(try #require(field.drifts[.window(7)]).volume == piled)
        #expect(field.grains.count == falling)
    }

    @Test
    func `swept snow is thrown off along the pointer, with powder`() throws {
        var field: SnowField = Self.snowyField()
        let piled: Float = try #require(field.drifts[.window(7)]).volume
        let falling: Int = field.grains.count
        let powder: Int = field.puffs.count

        field.movePointer(to: .init(250, 505))
        field.advance(to: field.now + Self.frameDuration)
        field.movePointer(to: .init(290, 505))

        let thrown: [Grain] = .init(field.grains.dropFirst(falling))
        let swept: Float = piled - (try #require(field.drifts[.window(7)]).volume)
        #expect(swept > 0)
        #expect(!thrown.isEmpty)
        #expect(thrown.allSatisfy { $0.velocity.x > 0 && $0.velocity.y > 0 })
        #expect(field.puffs.count > powder)
        (1...10).forEach { _ in field.advance(to: field.now + Self.frameDuration) }
        #expect(piled - (try #require(field.drifts[.window(7)]).volume) > swept / 2)
    }

    @Test
    func `a window in front keeps the snow it hides`() throws {
        var drift: SnowDrift = Self.snowyDrift()
        _ = drift.hide(under: [.init(x: 240, y: 503, width: 60, height: 300)])
        let piled: [Float] = drift.heights

        let hidden: [Spill] = drift.sweep(try #require(Self.pass(at: 505)))
        let shown: [Spill] = drift.sweep(try #require(Self.pass(at: 501)))

        #expect(hidden.isEmpty)
        #expect(!shown.isEmpty)
        #expect(drift.heights.indices.filter { drift.heights[$0] != piled[$0] }.allSatisfy { Self.nearBrush.contains($0) })
    }

    @Test(arguments: [495, 530] as [Float])
    func `a pass below the ledge top or above the pile sweeps nothing`(height: Float) throws {
        var drift: SnowDrift = Self.snowyDrift()
        let piled: [Float] = drift.heights

        let spills: [Spill] = drift.sweep(try #require(Self.pass(at: height)))

        #expect(spills.isEmpty)
        #expect(drift.heights == piled)
    }

    @Test
    func `a sweep near an end keeps every column within its capacity`() throws {
        var drift: SnowDrift = Self.snowyDrift()

        _ = drift.sweep(try #require(Sweep(from: .init(95, 505), to: .init(140, 505), over: Self.frameDuration)))

        #expect(zip(drift.heights, drift.capacity).allSatisfy { $0 <= $1 })
    }

    @Test
    func `swept snow never lands back on its own drift`() throws {
        var field: SnowField = Self.snowyField()
        let falling: Int = field.grains.count

        field.movePointer(to: .init(250, 505))
        field.advance(to: field.now + Self.frameDuration)
        field.movePointer(to: .init(290, 505))

        let thrown: [Grain] = .init(field.grains.dropFirst(falling))
        #expect(!thrown.isEmpty)
        #expect(thrown.allSatisfy { $0.catching == .anyDriftBut(.window(7)) })
    }
}
