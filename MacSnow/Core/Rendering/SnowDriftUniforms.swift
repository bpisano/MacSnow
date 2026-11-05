//
//  SnowDriftUniforms.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// The shape of one drift on the GPU, its heights and occluders aside. Field order matches `SnowDriftUniforms` in `Snow.metal`.
struct SnowDriftUniforms: Equatable, Sendable {
    /// Left edge of the ledge, in points.
    let left: Float
    /// Height of the ledge top, in points.
    let top: Float
    /// Width of the ledge, in points.
    let width: Float
    /// Width of one column, in points.
    let columnWidth: Float
    /// Height of the highest column, in points.
    let peak: Float
    /// Number of columns.
    let columns: UInt32
    /// Number of occluders hiding the drift.
    let occluders: UInt32
    /// How far the pile top leans across its ledge, in points.
    let offset: Float

    /// Captures `drift` as it is now.
    /// - Parameters:
    ///   - drift: The drift to draw.
    init(drift: SnowDrift) {
        left = drift.left
        top = drift.top
        width = drift.width
        columnWidth = SnowDrift.columnWidth
        peak = drift.peak
        columns = .init(drift.heights.count)
        occluders = .init(drift.occluders.count)
        offset = drift.offset
    }
}
