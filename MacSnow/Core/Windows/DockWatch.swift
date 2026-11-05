//
//  DockWatch.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import AppKit

/// Reads where the Dock's tile row is while started: now, every 2 s and on every screen change.
///
/// Only a Dock shown along a screen bottom has a tile row here: a hidden Dock lies off screen, a side Dock stands upright.
@MainActor
final class DockWatch: SurfaceTracking, DockWatching {
    private static let pollInterval: TimeInterval = 2

    /// The Dock's tile row in Cocoa global coordinates. `nil` while stopped, without Accessibility,
    /// or when the Dock is hidden or on a side.
    private(set) var tileRow: CGRect?

    /// Whether the polling timer is running.
    var isWatching: Bool {
        timer != nil
    }

    private let reader: any DockReader
    private let screenFrames: @MainActor () -> [CGRect]
    private var timer: Timer?
    private var screenChanges: Task<Void, Never>?

    /// Creates a stopped watch.
    /// - Parameters:
    ///   - reader: Where the Dock's geometry is read from.
    ///   - screenFrames: The screen frames in Cocoa global coordinates, the primary screen first.
    init(
        reader: any DockReader = AXDockReader(),
        screenFrames: @escaping @MainActor () -> [CGRect] = { NSScreen.screens.map(\.frame) }
    ) {
        self.reader = reader
        self.screenFrames = screenFrames
    }

    isolated deinit {
        timer?.invalidate()
        screenChanges?.cancel()
    }

    /// Reads now, then every 2 s on the main run loop and on every screen change. Does nothing when already watching.
    func start() {
        guard timer == nil else {
            return
        }
        read()
        let timer: Timer = .init(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.read()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        screenChanges = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didChangeScreenParametersNotification) {
                self?.read()
            }
        }
    }

    /// Stops reading and forgets the tile row.
    func stop() {
        timer?.invalidate()
        timer = nil
        screenChanges?.cancel()
        screenChanges = nil
        tileRow = nil
    }

    /// Reads the Dock once and updates `tileRow`.
    func read() {
        let screens: [CGRect] = screenFrames()
        guard
            let primaryScreen = screens.first,
            let frame = reader.tileRowFrame()
        else {
            tileRow = nil
            return
        }
        let coordinates: ScreenCoordinates = .init(primaryScreenMaxY: primaryScreen.maxY)
        let tileRow: CGRect = coordinates.cocoaFrame(fromCoreGraphics: frame)
        let isAlongBottom: Bool = tileRow.width > tileRow.height
        let isShown: Bool = screens.contains { $0.contains(tileRow) }
        self.tileRow = isAlongBottom && isShown ? tileRow : nil
    }
}
