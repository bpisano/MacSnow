//
//  SnowField.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
import Foundation

/// The flakes falling over one screen, in points with the origin at the bottom left.
///
/// While spawning, keeps one flake alive per `areaPerFlake`: each flake falling out is born again
/// above the screen. Stopped, flakes only fall out and the drifts melt until the field is empty.
///
/// Flakes reaching a ledge land, their landings solved twenty-four times a second over the time elapsed since:
/// they leave the field and their snow piles on the ledge's drift.
/// Snow spilling off a drift falls as grains, which land the same way; a hard landing puffs powder.
/// A pointer passing fast over a drift sweeps snow off it, as grains and powder.
/// Cleared, every drift spills whole, its grains falling through every ledge.
/// Spills larger than a clump crumble into a few grains of mixed sizes, falling together as a heap.
/// Once the clock passes `clockSpan`, every clock moves back by it and the wind forgets the distance it blew,
/// so neither grows large enough to lose precision.
struct SnowField {
    /// Screen area per living flake, in square points.
    static let areaPerFlake: Float = 6000
    /// Room kept off each edge, so flakes cross it whole when they wrap, enter or leave.
    static let margin: Float = 8
    /// Snow area a landed flake adds to its drift, per square point of its size.
    static let packing: Float = 0.9
    /// Most grains falling at once: past it, the oldest are dropped.
    static let mostGrains: Int = 2000
    /// Most puffs at once: past it, the oldest are dropped.
    static let mostPuffs: Int = 400
    /// Snow area a grain gathers from neighbouring spills before falling, in square points.
    static let clumpArea: Float = 16
    /// Falling speed from which a landing grain puffs powder, in points per second.
    static let hardLanding: Float = 200
    /// Height every drift loses once spawning stopped, in points per second.
    static let melting: Float = 2
    /// Field clock from which every clock moves back by it, in seconds.
    static let clockSpan: Float = 3600

    private static let longestStep: Float = 0.1
    private static let largeShare: Float = 0.15
    private static let clumpReach: Float = 6
    private static let grainJitter: Float = 10
    private static let pieces: ClosedRange<Int> = 3...6
    private static let smallestPiece: Float = 0.3
    private static let scatter: Float = 2.5
    private static let landingCheck: Float = 1.0 / 24.0

    /// Screen width.
    let width: Float
    /// Screen height.
    let height: Float
    /// The flakes alive, on screen or about to enter it.
    private(set) var flakes: [SnowFlake] = []
    /// The clumps falling off drifts, oldest first.
    private(set) var grains: [Grain] = []
    /// The powder clouds, oldest first.
    private(set) var puffs: [Puff] = []
    /// The wind blowing over every flake.
    private(set) var wind: Wind
    /// Field clock, in seconds.
    private(set) var now: Float = 0
    /// Seconds every clock moved back so far: the field clock is the time since the field started, less this.
    private(set) var epoch: Double = 0
    /// Whether flakes falling out are born again.
    private(set) var isSpawning: Bool = true
    /// The ledges catching snow, front to back, in screen points. A drift lasts as long as its ledge,
    /// hidden under the ledges in front of it: the snow they cover falls as grains.
    /// When a ledge leaves, closed or minimized, its whole drift falls as grains from where it was.
    /// When a ledge is resized, the snow that no longer fits falls as grains past it.
    var surfaces: [SnowSurface] = [] {
        didSet {
            guard surfaces != oldValue else {
                return
            }
            let kept: Set<SnowSurfaceID> = .init(surfaces.map(\.id))
            let leaving: [Spill] = oldValue
                .filter { !kept.contains($0.id) }
                .compactMap { drifts[$0.id] }
                .flatMap { drift in
                    var leaving: SnowDrift = drift
                    return leaving.spillAll()
                }
            let laid: [LaidDrift] = surfaces.enumerated().map { rank, surface in
                var drift: SnowDrift = drifts[surface.id] ?? .init(on: surface)
                let resized: [Spill] = drift.move(onto: surface)
                let hidden: [Spill] = drift.hide(under: surfaces.prefix(rank).map(\.frame))
                return .init(drift: drift, resized: resized, hidden: hidden)
            }
            drifts = .init(laid.map { ($0.drift.id, $0.drift) }, uniquingKeysWith: { first, _ in first })
            laid.forEach { release($0.resized, impulse: .zero, catching: .anyDriftBut($0.drift.id)) }
            release(leaving + laid.flatMap(\.hidden), impulse: .zero, catching: .anyDrift)
        }
    }
    /// The snow piled on each ledge.
    private(set) var drifts: [SnowSurfaceID: SnowDrift] = [:]

    private var random: any RandomNumberGenerator
    private var pointer: Pointer = .init()
    private var checkedAt: Float = 0

    /// Creates a field with its flakes spread above the screen, about to enter it.
    /// - Parameters:
    ///   - width: Screen width, in points.
    ///   - height: Screen height, in points.
    ///   - wind: The wind at clock zero.
    ///   - random: Shapes every flake, grain, puff and the wind.
    init(
        width: Float,
        height: Float,
        wind: Wind = .init(),
        random: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.width = width
        self.height = height
        self.wind = wind
        self.random = random
        fill()
    }

    /// Whether every flake and grain fell out, every puff faded, and every drift melted.
    var isEmpty: Bool {
        flakes.isEmpty && grains.isEmpty && puffs.isEmpty && drifts.values.allSatisfy { $0.peak == 0 }
    }

    /// The drifts in drawing order, back to front.
    var driftsBackToFront: [SnowDrift] {
        surfaces.reversed().compactMap { drifts[$0.id] }
    }

    private var capacity: Int {
        Int((width * height / Self.areaPerFlake).rounded())
    }

    private var landingZone: LandingZone {
        .init(drifts: surfaces.compactMap { drifts[$0.id] })
    }

    /// Moves the clock to `time`: the wind blows, flakes and grains reaching a ledge land on its drift,
    /// flakes and grains below the screen fall out, flakes are born again while spawning, drifts melt once it stopped,
    /// and puffs fade. After a jump longer than a frame, the flakes born again spread above the screen, as when spawning starts.
    /// Snow spilling off the drifts they land on, or thrown off by their ledge's motion, falls as new grains.
    /// Once the clock reaches `clockSpan`, every clock moves back by it, and `epoch` grows by it.
    /// - Parameters:
    ///   - time: The new clock, in seconds: the time since the field started, less `epoch`.
    /// - Returns: Whether flakes were added, removed or moved back in time.
    @discardableResult
    mutating func advance(to time: Float) -> Bool {
        let elapsed: Float = max(time - now, 0)
        let step: Float = min(elapsed, Self.longestStep)
        wind.blow(for: step, turning: uniform(-1...1))
        now = time
        let count: Int = flakes.count
        var spills: [Spill] = landFlakes(at: time)
        let retired: Int = count - flakes.count
        if isSpawning {
            let isJump: Bool = elapsed > Self.longestStep
            let reborn: [SnowFlake] = (0..<retired).map { _ in makeFlake(lift: isJump ? uniform(0...height) : 0) }
            flakes += reborn
        } else {
            drifts.keys.forEach { drifts[$0]?.melt(by: Self.melting * step) }
        }
        spills += moveGrains(for: step)
        puffs = puffs.map { $0.spreading(for: step) }.filter { !$0.isGone }
        release(spills, impulse: .zero, catching: .anyDrift)
        for surface in surfaces {
            let shakes: [Shake] = drifts[surface.id]?.sway(to: time, for: step) ?? []
            for shake in shakes {
                release(drifts[surface.id]?.shed(shake) ?? [], impulse: shake.impulse, catching: .anyDriftBut(surface.id))
            }
        }
        guard now >= Self.clockSpan else {
            return retired > 0
        }
        rewind(by: Self.clockSpan)
        return true
    }

    /// Spills every drift whole: its snow falls as grains which, like the grains already falling,
    /// fall through every ledge and off the screen.
    mutating func clear() {
        let spills: [Spill] = drifts.keys.flatMap { drifts[$0]?.spillAll() ?? [] }
        release(spills, impulse: .zero, catching: .anyDrift)
        grains = grains.map { $0.fallingThrough() }
    }

    /// Follows the pointer to `position` at the current clock. Passing fast since the previous call, it sweeps
    /// the snow off the drifts it crosses: the snow is thrown along, with powder, never back onto the drift it left.
    /// - Parameters:
    ///   - position: Where the pointer is, in points.
    mutating func movePointer(to position: SIMD2<Float>) {
        guard let sweep = pointer.move(to: position, at: now) else {
            return
        }
        for surface in surfaces {
            let spills: [Spill] = drifts[surface.id]?.sweep(sweep) ?? []
            release(spills, impulse: sweep.impulse, catching: .anyDriftBut(surface.id)).forEach { puff(from: $0, at: $0.position) }
        }
    }

    /// Spawns flakes again, the missing ones spread above the screen.
    mutating func startSpawning() {
        isSpawning = true
        fill()
    }

    /// Stops spawning: flakes not on screen yet are dropped, the others keep falling out, and the drifts melt.
    mutating func stopSpawning() {
        isSpawning = false
        let ceiling: Float = height + Self.margin
        flakes = flakes.filter { position(of: $0, at: now).y < ceiling }
    }

    /// Where `flake` is at `time`, with the wind as far as it blew now, wrapped across the width.
    /// - Parameters:
    ///   - flake: The flake to place.
    ///   - time: The moment, in seconds of the field clock.
    /// - Returns: The flake center, in points.
    func position(of flake: SnowFlake, at time: Float) -> SIMD2<Float> {
        flake.position(at: time, wind: wind.offset, width: width)
    }

    @discardableResult
    private mutating func release(_ spills: [Spill], impulse: SIMD2<Float>, catching: GrainCatch) -> [Grain] {
        let clumps: [Spill] = Spill.clumps(of: spills, upTo: Self.clumpArea, within: Self.clumpReach)
        let pieces: [Spill] = clumps.flatMap { crumble($0) }
        let released: [Grain] = pieces.map { piece in
            .init(
                position: piece.position + .init(uniform(-Self.scatter...Self.scatter), uniform(0...Self.scatter)),
                velocity: impulse + .init(uniform(-Self.grainJitter...Self.grainJitter), uniform(0...Self.grainJitter)),
                area: piece.area,
                turn: uniform(0...(2 * .pi)),
                catching: catching
            )
        }
        grains += released
        grains.removeFirst(max(grains.count - Self.mostGrains, 0))
        return released
    }

    private mutating func crumble(_ clump: Spill) -> [Spill] {
        guard clump.area > Self.clumpArea else {
            return [clump]
        }
        let count: Int = uniform(Self.pieces)
        return clump.crumbled(into: (0..<count).map { _ in pieceWeight() })
    }

    private mutating func puff(from grain: Grain, at point: SIMD2<Float>) {
        let rise: SIMD2<Float> = .init(0.15 * grain.velocity.x + uniform(-15...15), uniform(10...30))
        puffs.append(
            .init(
                position: point,
                velocity: rise,
                size: max(3 * grain.size, 6),
                alpha: uniform(0.25...0.4),
                life: uniform(0.5...0.9)
            )
        )
        puffs.removeFirst(max(puffs.count - Self.mostPuffs, 0))
    }

    private mutating func fill() {
        let missing: Int = max(capacity - flakes.count, 0)
        let spawned: [SnowFlake] = (0..<missing).map { _ in makeFlake(lift: uniform(0...height)) }
        flakes += spawned
    }

    private mutating func makeFlake(lift: Float) -> SnowFlake {
        let isLarge: Bool = uniform(0...1) < Self.largeShare
        let size: Float = isLarge ? uniform(2.5...4) : uniform(1...2.5)
        let speed: Float = 20 + 9 * size + uniform(0...22)
        let tempo: Float = uniform(0.6...1.5)
        let bob: Float = uniform(0.04...0.12) * speed / (SnowFlake.bobWave.pace * tempo)
        let windShare: Float = uniform(0.55...0.95)
        let top: Float = height + Self.margin + bob + lift
        return .init(
            born: now,
            gone: now + (top + Self.margin + 2 * bob) / speed,
            lane: uniform(-Self.margin...(width + Self.margin)) - windShare * wind.offset,
            top: top,
            speed: speed,
            bob: bob,
            tempo: tempo,
            seed: uniform(0...(2 * .pi)),
            flutter: uniform(4...16),
            windShare: windShare,
            size: size,
            opacity: uniform(0.55...0.9),
            blur: uniform(0.25...0.75)
        )
    }

    private mutating func pieceWeight() -> Float {
        let unit: Float = uniform(0...1)
        return Self.smallestPiece + (1 - Self.smallestPiece) * unit * unit
    }

    private mutating func uniform(_ range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(random.next(upperBound: UInt(range.count)))
    }

    private mutating func uniform(_ range: ClosedRange<Float>) -> Float {
        let unit: Float = .init(random.next() >> 40) / 0x1p24
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}

private extension SnowField {
    /// A drift laid on its ledge, with the snow its resize spilled and the snow the ledges in front hid.
    struct LaidDrift {
        let drift: SnowDrift
        let resized: [Spill]
        let hidden: [Spill]
    }

    mutating func rewind(by duration: Float) {
        let blown: Float = wind.resetOffset()
        flakes = flakes.map { $0.rewound(by: duration, wind: blown, width: width) }
        now -= duration
        checkedAt -= duration
        epoch += Double(duration)
        drifts.keys.forEach { drifts[$0]?.rewind(by: duration) }
        pointer.rewind(by: duration)
    }

    mutating func landFlakes(at time: Float) -> [Spill] {
        let since: Float = checkedAt
        let checksLandings: Bool = time - since >= Self.landingCheck
        if checksLandings {
            checkedAt = time
        }
        let zone: LandingZone = landingZone
        let windOffset: Float = wind.offset
        let width: Float = self.width
        var spills: [Spill] = []
        var falling: [SnowFlake] = []
        falling.reserveCapacity(flakes.count)
        for flake in flakes {
            let isGone: Bool = flake.gone <= time
            let landing: Landing? = (checksLandings || isGone) && time > since
                ? zone.landing(
                    of: { flake.position(at: $0, wind: windOffset, width: width) },
                    from: since,
                    to: time,
                    catching: .anyDrift
                )
                : nil
            if let landing {
                let room: Float = drifts[landing.drift]?.room(at: landing.point.x) ?? 0
                let volume: Float = Self.packing * flake.size * flake.size * room
                spills += drifts[landing.drift]?.deposit(volume, at: landing.point.x) ?? []
            } else if !isGone {
                falling.append(flake)
            }
        }
        flakes = falling
        return spills
    }

    mutating func moveGrains(for step: Float) -> [Spill] {
        let zone: LandingZone = landingZone
        var spills: [Spill] = []
        var falling: [Grain] = []
        falling.reserveCapacity(grains.count)
        for start in grains {
            let end: Grain = start.falling(for: step)
            guard
                end.catching != .noDrift,
                let landing = zone.landing(
                    of: { start.position + (end.position - start.position) * $0 },
                    from: 0,
                    to: 1,
                    catching: end.catching
                )
            else {
                if end.position.y > -Self.margin {
                    falling.append(end)
                }
                continue
            }
            spills += drifts[landing.drift]?.deposit(end.area, at: landing.point.x) ?? []
            if -end.velocity.y > Self.hardLanding {
                puff(from: end, at: landing.point)
            }
        }
        grains = falling
        return spills
    }
}
