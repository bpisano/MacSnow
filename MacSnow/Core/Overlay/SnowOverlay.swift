//
//  SnowOverlay.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import AppKit
import QuartzCore

/// Click-through transparent panel covering one screen, above every window and on every Space.
///
/// While shown, piles snow on the tops of the windows on its screen, on the Dock when it sits there, and on the screen bottom,
/// and follows the pointer, without catching its clicks, so a fast pass sweeps the snow.
@MainActor
final class SnowOverlay: Overlay {
    private let panel: NSPanel
    private let loop: SnowLoop

    /// Creates an overlay covering `screen`, off screen until shown.
    /// - Parameters:
    ///   - screen: The screen to cover.
    ///   - renderer: Draws every frame.
    ///   - tracker: Reports the windows snow piles on, started by whoever shows the overlay.
    ///   - dockWatch: Reports the Dock's tile row snow piles on, started by whoever shows the overlay.
    init(screen: SnowScreen, renderer: any SnowRendering, tracker: any WindowTracking, dockWatch: any DockWatching) {
        let layer: CAMetalLayer = .init()
        layer.device = renderer.device
        layer.pixelFormat = .bgra8Unorm
        layer.isOpaque = false
        layer.framebufferOnly = true
        layer.contentsScale = screen.scale
        layer.drawableSize = .init(
            width: screen.frame.width * screen.scale,
            height: screen.frame.height * screen.scale
        )

        let view: NSView = .init(frame: .init(origin: .zero, size: screen.frame.size))
        view.layer = layer
        view.wantsLayer = true

        panel = .init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.contentView = view
        panel.setFrame(screen.frame, display: false)

        let screenFrame: CGRect = screen.frame
        loop = .init(
            layer: layer,
            renderer: renderer,
            field: .init(width: Float(screenFrame.width), height: Float(screenFrame.height)),
            surfaces: { [tracker, dockWatch] in
                SnowSurface.frontToBack(windows: tracker.surfaces, dockTileRow: dockWatch.tileRow, screen: screenFrame)
                    .map { Self.surface($0, seenFrom: screenFrame.origin) }
            },
            pointer: {
                let location: CGPoint = NSEvent.mouseLocation
                return .init(Float(location.x - screenFrame.minX), Float(location.y - screenFrame.minY))
            }
        )
    }

    private static func surface(_ surface: SnowSurface, seenFrom origin: CGPoint) -> SnowSurface {
        .init(
            id: surface.id,
            frame: surface.frame.offsetBy(dx: -origin.x, dy: -origin.y),
            zIndex: surface.zIndex,
            cornerRadius: surface.cornerRadius
        )
    }

    /// Puts the panel above every window and lets snow fall.
    func show() {
        panel.orderFrontRegardless()
        loop.start()
    }

    /// Spawns flakes again after `stopSnowing()`.
    func startSnowing() {
        loop.startSpawning()
    }

    /// Stops spawning flakes and returns once the others fell out and the drifts melted.
    func stopSnowing() async {
        for await _ in loop.stopSpawning() {
            break
        }
    }

    /// Lets every drift fall off the screen, while snow keeps falling.
    func clearSnow() {
        loop.clearSnow()
    }

    /// Stops drawing and closes the panel.
    func close() {
        loop.stop()
        panel.close()
    }
}
