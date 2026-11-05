//
//  Overlay.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// A transparent panel drawing the snow over one screen.
@MainActor
protocol Overlay: AnyObject, Sendable {
    /// Puts the overlay on screen and lets snow fall.
    func show()

    /// Spawns flakes again after `stopSnowing()`.
    func startSnowing()

    /// Stops spawning flakes, lets the others fall out and the drifts melt.
    ///
    /// Returns once the last flake fell out and the last drift melted, or early when snow starts again or the calling task is cancelled.
    func stopSnowing() async

    /// Lets the snow lying on screen fall off, while snow keeps falling.
    func clearSnow()

    /// Stops drawing and takes the overlay off screen for good.
    func close()
}
