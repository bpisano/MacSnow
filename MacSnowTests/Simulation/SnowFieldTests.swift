//
//  SnowFieldTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation
@testable import MacSnow
import Testing

@Suite
struct SnowFieldTests {
    private static let tolerance: Float = 0.001

    private let field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())

    @Test
    func `a flake starts at its spawn height, on its flutter`() {
        let flake: SnowFlake = .mock(born: 3, lane: 120, top: 700, seed: 1.2, flutter: 12)

        let position: SIMD2<Float> = field.position(of: flake, at: 3)

        #expect(position.y == 700)
        #expect(abs(position.x - 120) <= 12)
    }

    @Test
    func `a flake falls its mean speed over a full bob`() {
        let age: Float = 4
        let flake: SnowFlake = .mock(top: 900, speed: 50, bob: 6, tempo: 2 * .pi / (SnowFlake.bobWave.pace * age), seed: 0.3)

        let fallen: Float = field.position(of: flake, at: 0).y - field.position(of: flake, at: age).y

        #expect(abs(fallen - 200) < Self.tolerance)
    }

    @Test
    func `a flake keeps falling`() {
        let flake: SnowFlake = .mock(top: 900, speed: 25, bob: 3, tempo: 0.8, seed: 0.7, flutter: 18)

        let heights: [Float] = stride(from: 0, through: 30, by: 0.1).map { field.position(of: flake, at: $0).y }

        #expect(zip(heights, heights.dropFirst()).allSatisfy { $0 > $1 })
    }

    @Test
    func `a flake flutters within its amplitude`() {
        let flake: SnowFlake = .mock(lane: 300, tempo: 1, flutter: 10)

        let sideways: [Float] = stride(from: 0, through: 30, by: 0.1).map { field.position(of: flake, at: $0).x - 300 }

        #expect(sideways.allSatisfy { abs($0) <= 10 + Self.tolerance })
        #expect(sideways.contains { abs($0) > 5 })
    }

    @Test
    func `a flake follows its share of the wind`() {
        let windy: SnowField = .init(width: 600, height: 1000, wind: .init(offset: 30))
        let flake: SnowFlake = .mock(lane: 100, windShare: 0.5)

        let position: SIMD2<Float> = windy.position(of: flake, at: 0)

        #expect(abs(position.x - 115) < Self.tolerance)
    }

    @Test
    func `a flake leaving one side comes back on the other`() {
        let right: SnowFlake = .mock(lane: 600 + SnowField.margin + 5)
        let left: SnowFlake = .mock(lane: -SnowField.margin - 5)

        let fromRight: SIMD2<Float> = field.position(of: right, at: 0)
        let fromLeft: SIMD2<Float> = field.position(of: left, at: 0)

        #expect(abs(fromRight.x - (-SnowField.margin + 5)) < Self.tolerance)
        #expect(abs(fromLeft.x - (600 + SnowField.margin - 5)) < Self.tolerance)
    }

    @Test
    func `flakes stay within the wrapped width`() {
        var field: SnowField = self.field
        field.advance(to: 20)

        let lefts: [Float] = field.flakes.map { field.position(of: $0, at: 20).x }

        #expect(lefts.allSatisfy { $0 >= -SnowField.margin && $0 < 600 + SnowField.margin })
    }

    @Test
    func `spawns flakes in proportion to the screen area`() {
        let wide: SnowField = .init(width: 1200, height: 1000, random: SeededRandomNumberGenerator())

        #expect(field.flakes.count == 100)
        #expect(wide.flakes.count == 200)
    }

    @Test
    func `spawns flakes above the screen`() {
        #expect(field.flakes.allSatisfy { field.position(of: $0, at: 0).y >= 1000 + SnowField.margin })
    }

    @Test
    func `a flake is below the screen once gone`() {
        #expect(field.flakes.allSatisfy { field.position(of: $0, at: $0.gone).y < -SnowField.margin })
    }

    @Test
    func `keeps the flake count while spawning`() {
        var field: SnowField = self.field

        let changed: Bool = (1...120).map { field.advance(to: Float($0)) }.contains(true)

        #expect(changed)
        #expect(field.flakes.count == 100)
    }

    @Test
    func `stopping drops the flakes not on screen yet`() {
        var field: SnowField = self.field
        field.advance(to: 10)

        field.stopSpawning()

        #expect(!field.isSpawning)
        #expect(field.flakes.allSatisfy { field.position(of: $0, at: 10).y < 1000 + SnowField.margin })
    }

    @Test
    func `stopped, the field empties as flakes fall out`() {
        var field: SnowField = self.field
        field.advance(to: 20)
        field.stopSpawning()
        let falling: Int = field.flakes.count

        field.advance(to: 30)

        #expect(falling > 0)
        #expect(field.flakes.count < falling)
        field.advance(to: 200)
        #expect(field.isEmpty)
    }

    @Test
    func `spawning again fills the field back`() {
        var field: SnowField = self.field
        field.advance(to: 20)
        field.stopSpawning()
        field.advance(to: 200)

        field.startSpawning()

        #expect(field.flakes.count == 100)
    }

    @Test
    func `a resized window drops the snow that no longer fits past it, never catching it back`() throws {
        var field: SnowField = self.field
        let ledge: SnowSurface = .mock(id: .window(7), frame: .init(x: 100, y: 200, width: 400, height: 300), zIndex: 0)
        field.surfaces = [ledge]
        (1...3600).forEach { field.advance(to: Float($0) / 60) }
        let piled: Float = try #require(field.drifts[.window(7)]).volume

        field.surfaces = [.mock(id: .window(7), frame: .init(x: 100, y: 200, width: 200, height: 300), zIndex: 0)]

        let kept: Float = try #require(field.drifts[.window(7)]).volume
        let thrown: [Grain] = field.grains.filter { $0.catching == .anyDriftBut(.window(7)) }
        let area: Float = thrown.reduce(0) { $0 + $1.area }
        field.advance(to: 60 + 0.25)
        let falling: Float = field.grains.filter { $0.catching == .anyDriftBut(.window(7)) }.reduce(0) { $0 + $1.area }
        #expect(!thrown.isEmpty)
        #expect(abs(area - (piled - kept)) < 0.01)
        #expect(abs(falling - area) < 0.01)
    }
}
