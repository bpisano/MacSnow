//
//  SnowDrift.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics

/// The snow piled on one ledge, as a height per column above the ledge top, in screen points.
///
/// Each column holds up to its capacity: none over the ledge's rounded corners, then a ramp up to its depth.
/// The ground has no corners: every column holds `groundDeepest`.
/// Snow steeper than the angle of repose slumps onto the lower neighbours. Snow past capacity gathers past the nearest end
/// and breaks off in chunks, the end resting a while after each, the snow overflowing meanwhile melting away.
/// Windows in front hide the snow under them, and the snow on the columns whose ledge top they cover spills.
/// The pile rides its moving ledge on a spring, and rough motion knocks snow off the whole ledge.
struct SnowDrift: Identifiable, Sendable {
    /// Width of one column, in points.
    static let columnWidth: Float = 2.5
    /// Most snow a column holds on a window or the Dock, in points.
    static let deepest: Float = 15
    /// Most snow a column holds on the ground, in points.
    static let groundDeepest: Float = 22
    /// Distance past a rounded corner over which capacity grows to `deepest`, in points.
    static let ramp: Float = 16
    /// Most windows in front a drift keeps hiding it.
    static let mostOccluders: Int = 16
    /// Room drawn past the ledge top and the deepest snow, a pixel at most, in points.
    static let rim: Float = 1
    /// How fast a filling column stops taking snow: its room is its free share raised to this power.
    static let uptake: Float = 1.5

    private static let reach: Int = DriftShape.widestSpread

    /// The ledge.
    let id: SnowSurfaceID
    /// Most snow a column holds, in points.
    let depth: Float
    /// Left edge of the ledge.
    private(set) var left: Float
    /// Height of the ledge top, where the snow rests.
    private(set) var top: Float
    /// Width of the ledge.
    private(set) var width: Float
    /// Snow height of each column, left to right.
    private(set) var heights: [Float]
    /// Most snow each column holds, left to right.
    private(set) var capacity: [Float]
    /// Frames of the windows in front hiding the drift, front-most first, clipped to its bounds.
    private(set) var occluders: [CGRect] = []

    private let ramp: Float?
    /// How the pile rides its moving ledge.
    private var motion: DriftMotion = .init()
    private var cornerRadius: Float
    private var overhangs: [End: Overhang] = [:]
    private var clock: Float = 0
    private var phase: Float = 0

    /// Creates a bare drift on `surface`.
    /// - Parameters:
    ///   - surface: The ledge, its frame in screen points.
    init(on surface: SnowSurface) {
        id = surface.id
        switch surface.id {
        case .ground:
            depth = Self.groundDeepest
            ramp = nil
        case .window, .dock:
            depth = Self.deepest
            ramp = Self.ramp
        }
        left = Float(surface.frame.minX)
        top = Float(surface.frame.maxY)
        width = Float(surface.frame.width)
        cornerRadius = Float(surface.cornerRadius)
        capacity = DriftShape.capacity(width: width, cornerRadius: cornerRadius, depth: depth, ramp: ramp, columnWidth: Self.columnWidth)
        heights = .init(repeating: 0, count: capacity.count)
    }

    /// Right edge of the ledge.
    var right: Float {
        left + width
    }

    /// Where the pile top sits across its ledge, in points: the snow leans this far, none at the ledge top.
    var offset: Float {
        motion.offset
    }

    /// Height of the highest column.
    var peak: Float {
        heights.max() ?? 0
    }

    /// Where the drift can be drawn: the ledge span, from the ledge top up to the deepest snow, a rim around.
    var bounds: CGRect {
        .init(
            x: CGFloat(left),
            y: CGFloat(top - Self.rim),
            width: CGFloat(width),
            height: CGFloat(depth + 2 * Self.rim)
        )
    }

    /// Snow area piled on the ledge and gathered past its ends, in square points.
    var volume: Float {
        heights.reduce(0, +) * Self.columnWidth + overhangs.values.reduce(0) { $0 + $1.area }
    }

    /// Follows the ledge to `surface`. The snow moves along, its top lagging behind the motion both ends share,
    /// so a resize alone leaves it still. On a resize, the snow stays where it lies on screen, to the sub-column:
    /// the columns past the new ends spill, with the snow gathered past an end they held, and the snow over
    /// the new capacity spills.
    /// - Parameters:
    ///   - surface: The ledge as it is now, its frame in screen points.
    /// - Returns: The snow a resize spills: one spill per column past the new ends, from where its snow surface lay,
    ///   then the snow past a cut end, then one spill per column over capacity, from its kept snow surface. None on a move.
    @discardableResult
    mutating func move(onto surface: SnowSurface) -> [Spill] {
        let newLeft: Float = .init(surface.frame.minX)
        let newTop: Float = .init(surface.frame.maxY)
        let newWidth: Float = .init(surface.frame.width)
        let newCornerRadius: Float = .init(surface.cornerRadius)
        motion.follow(left: newLeft - left, right: newLeft + newWidth - right, top: newTop - top)
        let isResized: Bool = newWidth != width || newCornerRadius != cornerRadius
        let columnShift: Float = (newLeft - left) / Self.columnWidth + phase
        let shift: Int = .init(columnShift.rounded())
        let resized: [Float] = DriftShape.capacity(
            width: newWidth,
            cornerRadius: newCornerRadius,
            depth: depth,
            ramp: ramp,
            columnWidth: Self.columnWidth
        )
        let cut: [Spill] = isResized ? empty(heights.indices.filter { !resized.indices.contains($0 - shift) }) : []
        left = newLeft
        top = newTop
        guard isResized else {
            return []
        }
        phase = columnShift - Float(shift)
        width = newWidth
        cornerRadius = newCornerRadius
        capacity = resized
        let shifted: [Float] = capacity.indices.map { heights.indices.contains($0 + shift) ? heights[$0 + shift] : 0 }
        heights = zip(shifted, capacity).map { min($0, $1) }
        let excess: [Spill] = shifted.indices.filter { shifted[$0] > heights[$0] }.map { column in
            let area: Float = (shifted[column] - heights[column]) * Self.columnWidth
            return .init(position: .init(center(of: column), top + heights[column]), area: area)
        }
        return cut + excess
    }

    /// Hides the drift under the windows in front, and spills the snow on the columns whose ledge top they cover,
    /// with the snow gathered past a covered end.
    /// - Parameters:
    ///   - frames: Frames of the windows in front, front-most first, in screen points.
    /// - Returns: The snow spilled, one spill per column, from its snow surface, then the snow past a covered end.
    mutating func hide(under frames: [CGRect]) -> [Spill] {
        let bounds: CGRect = bounds
        occluders = Array(
            frames.lazy
                .map { $0.intersection(bounds) }
                .filter { !$0.isEmpty }
                .prefix(Self.mostOccluders)
        )
        return spillCovered(heights.indices)
    }

    /// Whether a window in front covers the ledge top at `across`.
    /// - Parameters:
    ///   - across: Distance from the screen's left edge, in points.
    /// - Returns: `true` when the ledge top point at `across` lies in an occluder.
    func isCovered(at across: Float) -> Bool {
        let ledge: CGPoint = .init(x: CGFloat(across), y: CGFloat(top))
        return occluders.contains { $0.contains(ledge) }
    }

    /// Snow height at `across`, linear between column centers, the end columns held flat past the edges.
    /// - Parameters:
    ///   - across: Distance from the screen's left edge, in points.
    /// - Returns: The height above the ledge top, in points.
    func height(at across: Float) -> Float {
        let last: Float = .init(heights.count - 1)
        let along: Float = min(max((across - left) / Self.columnWidth - 0.5, 0), last)
        let column: Int = .init(along.rounded(.down))
        let next: Int = min(column + 1, heights.count - 1)
        let blend: Float = along - Float(column)
        return heights[column] + (heights[next] - heights[column]) * blend
    }

    /// Share of a flake's snow the column at `across` still takes: all on bare ledge, its free share raised to `uptake`
    /// as it fills, so a nearly full column takes little, none once full.
    /// - Parameters:
    ///   - across: Distance from the screen's left edge, in points.
    /// - Returns: A share from `0` to `1`.
    func room(at across: Float) -> Float {
        let column: Int = min(max(Int(((across - left) / Self.columnWidth).rounded(.down)), 0), heights.count - 1)
        guard capacity[column] > 0 else {
            return 0
        }
        return pow(max(1 - heights[column] / capacity[column], 0), Self.uptake)
    }

    /// Whether `point` lies over the ledge and in the snow, or under the bare ledge top.
    /// - Parameters:
    ///   - point: A point on screen, in points.
    /// - Returns: `true` when `point` is at or below the snow surface within the ledge span.
    func buries(_ point: SIMD2<Float>) -> Bool {
        point.x >= left && point.x < right && clearance(of: point) <= 0
    }

    /// Adds snow at `across`, spread as a rounded bump over a few columns, wider for more snow. Then lets it slump
    /// and smooths it near its column, gathers what overflows capacity past the nearest end, unless it rests,
    /// and spills what lies on covered columns near it.
    /// - Parameters:
    ///   - volume: Snow area, in square points.
    ///   - across: Distance from the screen's left edge, in points.
    /// - Returns: The snow spilled: a chunk breaking off an end once enough gathered past it, at the ledge top,
    ///   then one spill per covered column, and the snow past a covered end.
    mutating func deposit(_ volume: Float, at across: Float) -> [Spill] {
        let column: Int = min(max(Int(((across - left) / Self.columnWidth).rounded(.down)), 0), heights.count - 1)
        DriftShape.spread(volume, at: column, over: &heights, columnWidth: Self.columnWidth)
        let nearby: Range<Int> = max(column - Self.reach, 0)..<min(column + Self.reach + 1, heights.count)
        return settle(nearby) + spillCovered(nearby)
    }

    /// Removes the snow on `columns`, to fall as grains. Emptying an end column also drops the snow gathered past that end.
    /// - Parameters:
    ///   - columns: The columns to empty, left to right from `0`. Columns past the drift are ignored.
    /// - Returns: The snow spilled, one spill per column holding snow, from its snow surface, then the snow past an emptied end.
    mutating func spill(_ columns: Range<Int>) -> [Spill] {
        empty(columns.filter(heights.indices.contains))
    }

    /// Removes all the snow, to fall as grains, the snow gathered past the ends included.
    /// - Returns: The snow spilled, one spill per column holding snow, from its snow surface, then the snow past the ends.
    mutating func spillAll() -> [Spill] {
        spill(heights.indices)
    }

    /// Lowers every column by `depth`, down to bare ledge, and melts the snow gathered past the ends at once.
    /// The snow melts away, no grains fall.
    /// - Parameters:
    ///   - depth: Height lost, in points.
    mutating func melt(by depth: Float) {
        heights = heights.map { max($0 - depth, 0) }
        overhangs.removeAll()
    }

    /// Springs the pile back over its ledge, reads how the ledge moved up to `time`, and keeps `time` for the ends to rest.
    /// - Parameters:
    ///   - time: The moment, in seconds.
    ///   - step: Elapsed time since the last call, in seconds.
    /// - Returns: The snow the ledge motion throws off, to pass to `shed(_:)`.
    mutating func sway(to time: Float, for step: Float) -> [Shake] {
        clock = time
        return motion.advance(to: time, for: step)
    }

    /// Moves every moment the drift keeps back by `duration`, as the field clock moves back.
    /// - Parameters:
    ///   - duration: How far the clock moves back, in seconds.
    mutating func rewind(by duration: Float) {
        clock -= duration
        motion.rewind(by: duration)
        overhangs.keys.forEach { overhangs[$0]?.rewind(by: duration) }
    }

    /// Sweeps `Sweep.share` of the snow off each column its brush crosses where no window in front hides it,
    /// then slumps and smooths the hollow round, and gathers what overflows capacity past the nearest end, unless it rests.
    /// - Parameters:
    ///   - sweep: The pointer passing.
    /// - Returns: The snow swept, one spill per column, from its snow surface before the sweep,
    ///   then a chunk breaking off an end once enough gathered past it, at the ledge top.
    mutating func sweep(_ sweep: Sweep) -> [Spill] {
        let radius: Float = Sweep.brush / 2
        let swept: [Int] = heights.indices.filter { column in
            let across: Float = center(of: column)
            guard
                heights[column] > 0,
                let touch = sweep.entry(
                    across: (across - radius)...(across + radius),
                    upward: top...(top + heights[column] + Sweep.reach)
                )
            else {
                return false
            }
            let point: CGPoint = .init(x: CGFloat(touch.x), y: CGFloat(touch.y))
            return !occluders.contains { $0.contains(point) }
        }
        let spills: [Spill] = swept.map { column in
            .init(
                position: .init(center(of: column), top + heights[column]),
                area: Sweep.share * heights[column] * Self.columnWidth
            )
        }
        swept.forEach { heights[$0] *= 1 - Sweep.share }
        guard let first = swept.first, let last = swept.last else {
            return spills
        }
        return spills + settle(max(first - Self.reach, 0)..<min(last + Self.reach + 1, heights.count))
    }

    /// Throws `shake`'s share of a full drift off the whole ledge: every column loses the same part of its snow,
    /// and the snow gathered past the ends drops.
    /// - Parameters:
    ///   - shake: The snow to throw.
    /// - Returns: The snow thrown, one spill per column it came from, at its snow surface, then the snow past the ends.
    mutating func shed(_ shake: Shake) -> [Spill] {
        let piled: Float = heights.reduce(0, +)
        let kept: Float = piled > 0 ? max(1 - shake.share * capacity.reduce(0, +) / piled, 0) : 1
        let spills: [Spill] = heights.indices.filter { heights[$0] > 0 }.map { column in
            .init(
                position: .init(center(of: column), top + heights[column] * kept),
                area: heights[column] * (1 - kept) * Self.columnWidth
            )
        }
        heights = heights.map { $0 * kept }
        return spills.filter { $0.area > 0 } + drop(End.allCases)
    }

    private func clearance(of point: SIMD2<Float>) -> Float {
        point.y - top - height(at: point.x)
    }

    private func center(of column: Int) -> Float {
        left + (Float(column) + 0.5) * Self.columnWidth
    }

    private func endColumn(of end: End) -> Int {
        end == .left ? 0 : heights.count - 1
    }

    private func edge(of end: End) -> SIMD2<Float> {
        .init(end == .left ? left - Self.columnWidth : right + Self.columnWidth, top)
    }

    private mutating func spillCovered(_ columns: Range<Int>) -> [Spill] {
        empty(columns.filter { isCovered(at: center(of: $0)) })
    }

    private mutating func settle(_ columns: Range<Int>) -> [Spill] {
        DriftShape.slump(columns, of: &heights, columnWidth: Self.columnWidth)
        DriftShape.smooth(columns, of: &heights)
        let middle: Int = heights.count / 2
        return [
            gather(trim(columns.clamped(to: 0..<middle)), past: .left),
            gather(trim(columns.clamped(to: middle..<heights.count)), past: .right)
        ].compactMap { $0 }
    }

    private mutating func trim(_ columns: Range<Int>) -> Float {
        columns.reduce(0) { overflow, column in
            let excess: Float = max(heights[column] - capacity[column], 0)
            heights[column] -= excess
            return overflow + excess * Self.columnWidth
        }
    }

    private mutating func gather(_ overflow: Float, past end: End) -> Spill? {
        overhangs[end, default: .init()].gather(overflow, at: clock).map { .init(position: edge(of: end), area: $0) }
    }

    private mutating func drop(_ ends: [End]) -> [Spill] {
        ends.compactMap { end in
            let area: Float = overhangs[end]?.drop() ?? 0
            return area > 0 ? .init(position: edge(of: end), area: area) : nil
        }
    }

    private mutating func empty(_ columns: [Int]) -> [Spill] {
        let spilled: [Int] = columns.filter { heights[$0] > 0 }
        let spills: [Spill] = spilled.map { column in
            .init(position: .init(center(of: column), top + heights[column]), area: heights[column] * Self.columnWidth)
        }
        spilled.forEach { heights[$0] = 0 }
        return spills + drop(End.allCases.filter { columns.contains(endColumn(of: $0)) })
    }
}

private extension SnowDrift {
    /// One end of the ledge.
    enum End: CaseIterable, Sendable {
        case left
        case right
    }
}
