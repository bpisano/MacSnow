//
//  UIMenuBarViewModel.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import AppKit
import Observation

/// `MenuBarViewModel` backed by the `SnowStore`.
@MainActor
@Observable
final class UIMenuBarViewModel: MenuBarViewModel {
    /// Whether snow is falling.
    var isSnowing: Bool {
        get { store.isSnowing }
        set { store.isSnowing = newValue }
    }

    /// Whether snow is falling; clearing is offered only then.
    var canClearSnow: Bool {
        store.isSnowing
    }

    @ObservationIgnored private let store: SnowStore

    /// Creates a view model reading and driving `store`.
    /// - Parameters:
    ///   - store: The snow state.
    init(store: SnowStore) {
        self.store = store
    }

    /// Clears the snow lying on screen.
    func clearSnow() {
        store.clear()
    }

    /// Quits the app.
    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
