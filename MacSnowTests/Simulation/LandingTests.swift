//
//  LandingTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow
import Testing

@Suite
struct LandingTests {
    private static let frameDuration: Float = 1.0 / 60.0
    private static let lateLanding: Float = 6
    private static let ledge: SnowSurface = .mock(id: .window(7), frame: .init(x: 100, y: 200, width: 400, height: 300))

    @Test
    func `a flake path crosses the ledge at the frame it reaches it`() throws {
        let field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        let drift: SnowDrift = .init(on: Self.ledge)
        let flake: SnowFlake = .mock(lane: 300, top: 900, speed: 50, tempo: 1.2, seed: 0.4, flutter: 10)
        let path: (Float) -> SIMD2<Float> = { field.position(of: flake, at: $0) }

        let frame: Int = try #require(
            (0..<600).first { Landing.crossing(of: path, from: Float($0) * Self.frameDuration, to: Float($0 + 1) * Self.frameDuration, on: drift) != nil }
        )
        let start: Float = .init(frame) * Self.frameDuration
        let time: Float = try #require(Landing.crossing(of: path, from: start, to: start + Self.frameDuration, on: drift))

        #expect(abs(path(time).y - 500) < 0.1)
        #expect(abs(time - 8) < 0.2)
    }

    @Test
    func `flakes landing on a ledge pile into its drift and are born again`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.ledge]

        (1...1800).forEach { field.advance(to: Float($0) * Self.frameDuration) }

        let drift: SnowDrift = try #require(field.drifts[.window(7)])
        #expect(drift.volume > 0)
        #expect(field.flakes.count == 100)
    }

    @Test
    func `each flake reaching a ledge lands once, at most a landing check late`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [.mock(id: .ground, frame: .init(x: -20, y: 0, width: 640, height: 200), cornerRadius: 0)]
        var landed: Float = 0
        var lowest: Float = .infinity

        for frame in 1...1200 {
            let falling: [SnowFlake] = field.flakes
            field.advance(to: Float(frame) * Self.frameDuration)
            landed += falling
                .filter { !field.flakes.contains($0) }
                .reduce(0) { $0 + SnowField.packing * $1.size * $1.size }
            lowest = field.flakes.map { field.position(of: $0, at: field.now).y }.reduce(lowest, min)
        }

        let ground: SnowDrift = try #require(field.drifts[.ground])
        #expect(landed > 0)
        #expect(ground.volume <= landed * 1.001)
        #expect(ground.volume > 0.8 * landed)
        #expect(lowest > 200 - Self.lateLanding)
    }

    @Test
    func `no flake lands where a front window covers the ledge`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        let front: SnowSurface = .mock(id: .window(3), frame: .init(x: 0, y: 0, width: 600, height: 700), zIndex: 0)
        field.surfaces = [front, .mock(id: .window(7), frame: Self.ledge.frame, zIndex: 1)]

        (1...1800).forEach { field.advance(to: Float($0) * Self.frameDuration) }

        let hidden: SnowDrift = try #require(field.drifts[.window(7)])
        let shown: SnowDrift = try #require(field.drifts[.window(3)])
        #expect(hidden.volume == 0)
        #expect(shown.volume > 0)
    }

    @Test
    func `a moved window keeps its drift`() throws {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.ledge]
        (1...1800).forEach { field.advance(to: Float($0) * Self.frameDuration) }
        let heights: [Float] = try #require(field.drifts[.window(7)]).heights

        field.surfaces = [.mock(id: .window(7), frame: Self.ledge.frame.offsetBy(dx: 50, dy: -100))]

        let moved: SnowDrift = try #require(field.drifts[.window(7)])
        #expect(moved.heights == heights)
        #expect(moved.left == 150)
        #expect(moved.top == 400)
    }

    @Test
    func `a closed window drops its drift`() {
        var field: SnowField = .init(width: 600, height: 1000, random: SeededRandomNumberGenerator())
        field.surfaces = [Self.ledge, .mock(id: .window(9), zIndex: 1)]
        (1...600).forEach { field.advance(to: Float($0) * Self.frameDuration) }

        field.surfaces = [.mock(id: .window(9))]

        #expect(field.drifts[.window(7)] == nil)
        #expect(field.drifts[.window(9)] != nil)
        #expect(field.driftsBackToFront.map(\.id) == [.window(9)])
    }

    @Test
    func `snow sliding sideways off a ledge end lands where it crosses the ledge top`() throws {
        let drift: SnowDrift = .init(on: .mock(frame: .init(x: 100, y: 100, width: 200, height: 100), cornerRadius: 0))
        let path: (Float) -> SIMD2<Float> = { .init(250 + 100 * $0, 202 - 10 * $0) }

        let landing: Landing = try #require(LandingZone(drifts: [drift]).landing(of: path, from: 0, to: 1, catching: .anyDrift))

        #expect(landing.drift == drift.id)
        #expect(abs(landing.point.x - 270) < 0.1)
        #expect(abs(landing.point.y - 200) < 0.01)
    }
}
