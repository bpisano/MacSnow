//
//  InMemorySnowPreferences.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// `SnowPreferences` kept in memory only, for previews and tests.
final class InMemorySnowPreferences: SnowPreferences {
    /// Whether snow was falling when last set.
    var isSnowing: Bool

    /// Creates preferences starting at `isSnowing`.
    /// - Parameters:
    ///   - isSnowing: Whether snow is falling at first.
    init(isSnowing: Bool = false) {
        self.isSnowing = isSnowing
    }
}
