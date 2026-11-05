//
//  MockMenuBarViewModel.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Observation

/// `MenuBarViewModel` with fixed state, for previews.
@MainActor
@Observable
final class MockMenuBarViewModel: MenuBarViewModel {
    /// Whether snow is falling.
    var isSnowing: Bool
    /// Whether there is snow on screen to clear.
    let canClearSnow: Bool

    /// Creates a view model with the given state.
    /// - Parameters:
    ///   - isSnowing: Whether snow is falling.
    ///   - canClearSnow: Whether there is snow on screen to clear.
    init(isSnowing: Bool = false, canClearSnow: Bool = false) {
        self.isSnowing = isSnowing
        self.canClearSnow = canClearSnow
    }

    /// Does nothing.
    func clearSnow() {}

    /// Does nothing.
    func quit() {}
}
