//
//  ScreenWatching.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Reports the screens snow falls on.
@MainActor
protocol ScreenWatching {
    /// The screens now, then again every time they change.
    /// - Returns: Every screen, the primary screen first, yielded on each change.
    func screens() -> AsyncStream<[SnowScreen]>
}
