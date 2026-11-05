//
//  NSScreenWatch.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import AppKit

/// `ScreenWatching` backed by AppKit: reads the screens now and on every screen parameter change,
/// a display plugged or unplugged, moved or set to another resolution.
struct NSScreenWatch: ScreenWatching {
    private static let displayKey: NSDeviceDescriptionKey = .init("NSScreenNumber")

    private static var current: [SnowScreen] {
        NSScreen.screens.compactMap { screen in
            (screen.deviceDescription[displayKey] as? CGDirectDisplayID).map { id in
                .init(id: id, frame: screen.frame, scale: screen.backingScaleFactor)
            }
        }
    }

    /// The screens now, then again every time a display is plugged, unplugged, moved or set to another resolution.
    /// - Returns: Every screen, the primary screen first, yielded on each change.
    func screens() -> AsyncStream<[SnowScreen]> {
        let (screens, continuation): (AsyncStream<[SnowScreen]>, AsyncStream<[SnowScreen]>.Continuation) = AsyncStream.makeStream()
        continuation.yield(Self.current)
        let changes: Task<Void, Never> = .init {
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didChangeScreenParametersNotification) {
                continuation.yield(Self.current)
            }
        }
        continuation.onTermination = { _ in
            changes.cancel()
        }
        return screens
    }
}
