//
//  SnowOverlayFactory.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Makes a `SnowOverlay` per screen, all piling snow on the same windows and Dock.
@MainActor
struct SnowOverlayFactory: OverlayFactory {
    private let renderer: any SnowRendering
    private let tracker: any WindowTracking
    private let dockWatch: any DockWatching

    /// Creates a factory whose overlays draw with `renderer` on the windows `tracker` reports and the Dock `dockWatch` reports.
    /// - Parameters:
    ///   - renderer: Draws every frame of every overlay.
    ///   - tracker: Reports the windows snow piles on.
    ///   - dockWatch: Reports the Dock's tile row snow piles on.
    init(renderer: any SnowRendering, tracker: any WindowTracking, dockWatch: any DockWatching) {
        self.renderer = renderer
        self.tracker = tracker
        self.dockWatch = dockWatch
    }

    /// Makes an overlay covering `screen`.
    /// - Parameters:
    ///   - screen: The screen to cover.
    /// - Returns: The overlay, off screen until shown.
    func makeOverlay(covering screen: SnowScreen) -> any Overlay {
        SnowOverlay(screen: screen, renderer: renderer, tracker: tracker, dockWatch: dockWatch)
    }
}
