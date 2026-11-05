//
//  MenuBarViewModel.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Observation

/// State and actions of the menu bar menu.
@MainActor
protocol MenuBarViewModel: AnyObject, Observable {
    /// Whether snow is falling.
    var isSnowing: Bool { get set }
    /// Whether there is snow on screen to clear.
    var canClearSnow: Bool { get }

    /// Clears the snow lying on screen.
    func clearSnow()
    /// Quits the app.
    func quit()
}
