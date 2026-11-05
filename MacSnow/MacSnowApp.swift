//
//  MacSnowApp.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import OSLog
import SwiftUI

/// Menu bar app letting snow fall on the desktop.
@main
struct MacSnowApp: App {
    private static let logger: Logger = .init(subsystem: "com.bpisano.MacSnow", category: "app")

    @State private var store: SnowStore

    /// Restores the snow state and starts following it with the overlay.
    init() {
        let store: SnowStore = .init(preferences: UserDefaultsSnowPreferences())
        self.store = store
        guard let renderer = SnowRenderer() else {
            Self.logger.error("Metal unavailable, no overlay")
            return
        }
        let tracker: WindowTracker = .init()
        let dockWatch: DockWatch = .init()
        let overlayController: OverlayController = .init(
            store: store,
            factory: SnowOverlayFactory(renderer: renderer, tracker: tracker, dockWatch: dockWatch),
            screenWatch: NSScreenWatch(),
            trackers: [tracker, dockWatch]
        )
        Task { await overlayController.run() }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarCoordinator(store)
        } label: {
            MenuBarIcon(isSnowing: store.isSnowing)
        }
        .menuBarExtraStyle(.menu)
    }
}
