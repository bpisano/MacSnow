//
//  WindowShakeTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct WindowShakeTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let tolerance: Float = 0.001
    private static let ledge: SnowSurface = .mock(id: .window(7), frame: .init(x: 100, y: 200, width: 400, height: 300), zIndex: 1)

    private static func snowyDrift() -> SnowDrift {
        var drift: SnowDrift = .init(on: ledge)
        (0..<4000).forEach { index in _ = drift.deposit(6, at: 100 + Float(index % 400)) }
        return drift
    }

    private static func ledge(at left: Float, lifted: Float = 0) -> SnowSurface {
        .mock(id: .window(7), frame: .init(x: CGFloat(left), y: CGFloat(200 + lifted), width: 400, height: 300), zIndex: 1)
    }

    /// Moves `drift`'s ledge along `lefts`, one per frame, shedding what the motion throws.
    /// - Returns: The shakes, frame by frame.
    private static func ride(_ drift: inout SnowDrift, along lefts: [Float], from frame: Int = 1) -> [[Shake]] {
        lefts.enumerated().map { index, left in
            drift.move(onto: ledge(at: left))
            let shakes: [Shake] = drift.sway(to: Float(frame + index) * frameDuration, for: frameDuration)
            shakes.forEach { _ = drift.shed($0) }
            return shakes
        }
    }

    private static func shaking(strokes: Int, reach: Float = 60, framesPerStroke: Int = 6) -> [Float] {
        (0..<(strokes * framesPerStroke)).map { frame in
            let phase: Float = .pi * Float(frame) / Float(framesPerStroke)
            return 100 + reach * sin(phase)
        }
    }

    @Test
    func `a slow drag carries the drift, lagging, then it settles`() {
        var drift: SnowDrift = Self.snowyDrift()
        let piled: Float = drift.volume

        let dragged: [[Shake]] = Self.ride(&drift, along: (1...60).map { 100 + Float($0) * 1.5 })
        let lag: Float = drift.offset
        let rested: [[Shake]] = Self.ride(&drift, along: .init(repeating: 190, count: 60), from: 61)

        #expect(dragged.allSatisfy { $0.isEmpty })
        #expect(rested.allSatisfy { $0.isEmpty })
        #expect(lag < -1)
        #expect(lag >= -DriftMotion.mostOffset)
        #expect(abs(drift.offset) < Self.tolerance)
        #expect(drift.left == 190)
        #expect(drift.volume == piled)
    }

    @Test
    func `frames polled twice do not read as jolts`() {
        var drift: SnowDrift = Self.snowyDrift()

        let lefts: [Float] = (1...120).map { 100 + Float($0 / 2) * 8 }
        let shakes: [[Shake]] = Self.ride(&drift, along: lefts)

        #expect(shakes.allSatisfy { $0.isEmpty })
    }

    @Test
    func `the first shake knocks a quarter of a full drift off the whole ledge`() throws {
        var drift: SnowDrift = Self.snowyDrift()
        let piled: Float = drift.volume
        let middle: Float = drift.heights[80]

        let shakes: [Shake] = Self.ride(&drift, along: Self.shaking(strokes: 5, reach: 20, framesPerStroke: 12)).flatMap { $0 }

        let shake: Shake = try #require(shakes.first)
        #expect(shakes.count == 1)
        #expect(shake.share == DriftMotion.swingShare)
        #expect(drift.volume < piled * 0.8)
        #expect(drift.volume > 0)
        #expect(drift.heights[80] < middle * 0.8)
    }

    @Test
    func `further reversals knock more snow off`() {
        var drift: SnowDrift = Self.snowyDrift()

        let shares: [Float] = Self.ride(&drift, along: Self.shaking(strokes: 7, reach: 20, framesPerStroke: 12)).flatMap { $0 }.map(\.share)

        #expect(shares.count > 1)
        #expect(zip(shares, shares.dropFirst()).allSatisfy { $0 < $1 })
        #expect(shares.allSatisfy { $0 <= DriftMotion.mostSwingShare })
    }

    @Test
    func `enough shaking empties the drift`() {
        var drift: SnowDrift = Self.snowyDrift()

        _ = Self.ride(&drift, along: Self.shaking(strokes: 40))

        #expect(drift.volume == 0)
    }

    @Test
    func `a jolt throws part of the drift towards the trailing end`() throws {
        var drift: SnowDrift = Self.snowyDrift()
        let piled: Float = drift.volume

        let shakes: [Shake] = Self.ride(&drift, along: [100, 130]).flatMap { $0 }

        let jolt: Shake = try #require(shakes.first)
        #expect(shakes.count == 1)
        #expect(jolt.share == DriftMotion.joltShare)
        #expect(jolt.impulse.x < 0)
        #expect(drift.volume < piled * 0.8)
        #expect(drift.volume > piled / 2)
    }

    @Test
    func `shed snow leaves every column from its snow surface, none lost`() {
        var drift: SnowDrift = Self.snowyDrift()
        let piled: Float = drift.volume
        let before: [Float] = drift.heights

        let spills: [Spill] = drift.shed(.init(share: 0.25, impulse: .init(80, 0)))

        let shed: Float = spills.map(\.area).reduce(0, +)
        let fromColumns: [Spill] = spills.filter { $0.position.x > drift.left && $0.position.x < drift.right }
        #expect(abs(drift.volume + shed - piled) < piled * Self.tolerance)
        #expect(drift.volume == drift.heights.reduce(0, +) * SnowDrift.columnWidth)
        #expect(fromColumns.count == before.filter { $0 > 0 }.count)
        #expect(fromColumns.allSatisfy { abs($0.position.y - drift.top - drift.height(at: $0.position.x)) < Self.tolerance })
        let kept: Float = drift.heights[80] / before[80]
        #expect(kept < 1)
        #expect(zip(before, drift.heights).allSatisfy { abs($1 - kept * $0) < Self.tolerance })
    }

    @Test
    func `snow knocked off falls in front of its window`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.ledge]
        (1...1800).forEach { field.advance(to: Float($0) * Self.frameDuration) }
        let piled: Float = try #require(field.drifts[.window(7)]).volume

        let knocked: [Bool] = Self.shaking(strokes: 5, reach: 20, framesPerStroke: 12).enumerated().map { index, left in
            field.surfaces = [Self.ledge(at: left)]
            field.advance(to: 30 + Float(index + 1) * Self.frameDuration)
            return field.grains.contains { $0.catching == .anyDriftBut(.window(7)) }
        }
        (1...120).forEach { field.advance(to: 31 + Float($0) * Self.frameDuration) }

        let drift: SnowDrift = try #require(field.drifts[.window(7)])
        #expect(knocked.contains(true))
        #expect(drift.volume < piled * 0.8)
        #expect(!field.grains.contains { $0.catching == .anyDriftBut(.window(7)) })
    }

    @Test
    func `a ledge leaving drops its whole drift as grains`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.ledge]
        (1...1800).forEach { field.advance(to: Float($0) * Self.frameDuration) }
        let piled: Float = try #require(field.drifts[.window(7)]).volume
        let falling: Int = field.grains.count

        field.surfaces = []

        let released: Float = field.grains.dropFirst(falling).map(\.area).reduce(0, +)
        #expect(piled > 0)
        #expect(field.drifts[.window(7)] == nil)
        #expect(abs(released - piled) < piled * Self.tolerance)
    }
}
