//
//  SnowSurface.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics

/// A ledge catching snow: a window top, the Dock's tile row or the screen bottom.
struct SnowSurface: Identifiable, Equatable, Sendable {
    /// Which ledge this is.
    let id: SnowSurfaceID
    /// The ledge frame in Cocoa global coordinates, origin at the bottom-left of the primary screen.
    let frame: CGRect
    /// The front-to-back rank, `0` for the frontmost ledge.
    let zIndex: Int
    /// The radius of the ledge's rounded corners.
    let cornerRadius: CGFloat
}

extension SnowSurface {
    private static let dockCornerRadius: CGFloat = 16

    /// Every ledge of one screen, front to back: the Dock's tile row when it sits on it, drawn above every window,
    /// then the windows whose top edge lies on it, then the screen bottom.
    ///
    /// A window whose top edge spans two screens is a ledge on both: each screen piles the snow falling over its own part.
    /// - Parameters:
    ///   - windows: The window tops of every screen, front to back.
    ///   - dockTileRow: The Dock's tile row in Cocoa global coordinates, `nil` when it catches no snow.
    ///   - screen: The frame of the screen whose ledges these are, in Cocoa global coordinates.
    /// - Returns: The screen's Dock, windows and ground, each ranked behind the ones before from `0`.
    static func frontToBack(
        windows: [SnowSurface],
        dockTileRow: CGRect?,
        screen: CGRect
    ) -> [SnowSurface] {
        let dock: SnowSurface? = dockTileRow.flatMap { tileRow in
            guard screen.contains(tileRow) else {
                return nil
            }
            return .init(id: .dock, frame: tileRow, zIndex: 0, cornerRadius: dockCornerRadius)
        }
        let ground: SnowSurface = .init(
            id: .ground,
            frame: .init(x: screen.minX, y: screen.minY, width: screen.width, height: 0),
            zIndex: 0,
            cornerRadius: 0
        )
        let onScreen: [SnowSurface] = windows.filter { $0.hasTop(on: screen) }
        return ([dock].compactMap(\.self) + onScreen + [ground])
            .enumerated()
            .map { rank, surface in surface.ranked(rank) }
    }

    /// A surface with sensible defaults, any field overridable.
    static func mock(
        id: SnowSurfaceID = .window(1),
        frame: CGRect = .init(x: 100, y: 200, width: 800, height: 600),
        zIndex: Int = 0,
        cornerRadius: CGFloat = 10
    ) -> SnowSurface {
        .init(id: id, frame: frame, zIndex: zIndex, cornerRadius: cornerRadius)
    }

    private func hasTop(on screen: CGRect) -> Bool {
        frame.maxY > screen.minY
            && frame.maxY <= screen.maxY
            && frame.maxX > screen.minX
            && frame.minX < screen.maxX
    }

    private func ranked(_ zIndex: Int) -> SnowSurface {
        .init(id: id, frame: frame, zIndex: zIndex, cornerRadius: cornerRadius)
    }
}
