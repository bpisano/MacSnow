//
//  OverlayController.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Observation

/// Shows an overlay on every screen while snow is falling, and clears their snow on request.
/// When snow stops, closes them once the last flake fell out and the drifts melted.
///
/// Follows the screens: a new screen gets its overlay, a gone one loses it, the others keep theirs and their drifts.
@MainActor
final class OverlayController {
    private let store: SnowStore
    private let factory: any OverlayFactory
    private let screenWatch: any ScreenWatching
    private let trackers: [any SurfaceTracking]
    private var screens: [SnowScreen] = []
    private var overlays: [SnowScreen: any Overlay] = [:]
    private var phase: Phase = .hidden

    /// Creates a controller following `store`.
    /// - Parameters:
    ///   - store: Says whether snow is falling.
    ///   - factory: Makes the overlay of each screen.
    ///   - screenWatch: Reports the screens to cover.
    ///   - trackers: Follow the ledges every overlay piles snow on, started while overlays are up.
    init(
        store: SnowStore,
        factory: any OverlayFactory,
        screenWatch: any ScreenWatching,
        trackers: [any SurfaceTracking]
    ) {
        self.store = store
        self.factory = factory
        self.screenWatch = screenWatch
        self.trackers = trackers
    }

    private var screenOverlays: [any Overlay] {
        screens.compactMap { overlays[$0] }
    }

    /// Follows the snow state, the clear requests and the screens until the calling task is cancelled.
    func run() async {
        async let snowing: Void = followSnowing()
        async let clearing: Void = followClearRequests()
        async let screens: Void = followScreens()
        _ = await (snowing, clearing, screens)
    }

    private func followSnowing() async {
        let store: SnowStore = store
        for await isSnowing in Observations({ store.isSnowing }) {
            if isSnowing {
                startSnowing()
            } else {
                stopSnowing()
            }
        }
    }

    private func followClearRequests() async {
        for await _ in store.clearRequests where phase == .shown {
            screenOverlays.forEach { $0.clearSnow() }
        }
    }

    private func followScreens() async {
        for await screens in screenWatch.screens() {
            self.screens = screens
            uncoverGoneScreens()
            if phase == .shown {
                coverScreens()
            }
        }
    }

    private func startSnowing() {
        switch phase {
        case .shown:
            return
        case let .closing(draining):
            draining.cancel()
            screenOverlays.forEach { $0.startSnowing() }
        case .hidden:
            trackers.forEach { $0.start() }
        }
        phase = .shown
        coverScreens()
    }

    private func stopSnowing() {
        guard phase == .shown else { return }
        let draining: [any Overlay] = screenOverlays
        phase = .closing(
            Task {
                await withTaskGroup(of: Void.self) { group in
                    draining.forEach { overlay in
                        group.addTask { await overlay.stopSnowing() }
                    }
                }
                guard !Task.isCancelled else { return }
                hide()
            }
        )
    }

    private func coverScreens() {
        let uncovered: [SnowScreen] = screens.filter { overlays[$0] == nil }
        uncovered.forEach { overlays[$0] = factory.makeOverlay(covering: $0) }
        uncovered.compactMap { overlays[$0] }.forEach { $0.show() }
    }

    private func uncoverGoneScreens() {
        let gone: Set<SnowScreen> = .init(overlays.keys).subtracting(screens)
        gone.compactMap { overlays.removeValue(forKey: $0) }.forEach { $0.close() }
    }

    private func hide() {
        screenOverlays.forEach { $0.close() }
        overlays = [:]
        trackers.forEach { $0.stop() }
        phase = .hidden
    }
}

private extension OverlayController {
    enum Phase: Equatable {
        case hidden
        case shown
        case closing(Task<Void, Never>)
    }
}
