//
//  WindowTracker.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import AppKit

/// Polls the on-screen app windows while started, and reports their tops as snow surfaces.
@MainActor
final class WindowTracker: SurfaceTracking, WindowTracking {
    private static let pollInterval: TimeInterval = 1.0 / 60.0
    private static let minimumSide: CGFloat = 40
    private static let windowCornerRadius: CGFloat = 10

    /// The surfaces of the last poll, front to back. Empty while stopped.
    private(set) var surfaces: [SnowSurface] = []

    private let listing: any WindowListing
    private let ownPID: pid_t
    private let primaryScreenMaxY: @MainActor () -> CGFloat?
    private var timer: Timer?

    /// Creates a stopped tracker.
    /// - Parameters:
    ///   - listing: Where the on-screen windows are read from.
    ///   - ownPID: The process whose windows are never surfaces, this app by default.
    ///   - primaryScreenMaxY: The top edge of the primary screen in Cocoa coordinates, `nil` without screen.
    init(
        listing: any WindowListing = CGWindowListing(),
        ownPID: pid_t = ProcessInfo.processInfo.processIdentifier,
        primaryScreenMaxY: @escaping @MainActor () -> CGFloat? = { NSScreen.screens.first?.frame.maxY }
    ) {
        self.listing = listing
        self.ownPID = ownPID
        self.primaryScreenMaxY = primaryScreenMaxY
    }

    isolated deinit {
        timer?.invalidate()
    }

    /// Whether the polling timer is running.
    var isTracking: Bool {
        timer != nil
    }

    /// Polls now, then every 1/60 s on the main run loop. Does nothing when already tracking.
    func start() {
        guard timer == nil else {
            return
        }
        poll()
        let timer: Timer = .init(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// Stops polling and forgets the surfaces.
    func stop() {
        timer?.invalidate()
        timer = nil
        surfaces = []
    }

    /// Reads the windows once and updates `surfaces`.
    func poll() {
        guard let primaryScreenMaxY = primaryScreenMaxY() else {
            return
        }
        let coordinates: ScreenCoordinates = .init(primaryScreenMaxY: primaryScreenMaxY)
        surfaces = listing.windows()
            .filter(isSurface)
            .enumerated()
            .map { zIndex, record in
                .init(
                    id: .window(record.number),
                    frame: coordinates.cocoaFrame(fromCoreGraphics: record.bounds),
                    zIndex: zIndex,
                    cornerRadius: Self.windowCornerRadius
                )
            }
    }

    private func isSurface(_ record: WindowRecord) -> Bool {
        record.layer == 0
            && record.alpha > 0
            && record.ownerPID != ownPID
            && record.bounds.width >= Self.minimumSide
            && record.bounds.height >= Self.minimumSide
    }
}
