//
//  UserDefaultsSnowPreferences.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Foundation

/// `SnowPreferences` stored in `UserDefaults`.
final class UserDefaultsSnowPreferences: SnowPreferences {
    private static let isSnowingKey: String = "isSnowing"

    /// Whether snow was falling when last set, `false` until first set.
    var isSnowing: Bool {
        get { defaults.bool(forKey: Self.isSnowingKey) }
        set { defaults.set(newValue, forKey: Self.isSnowingKey) }
    }

    private let defaults: UserDefaults

    /// Creates preferences backed by `defaults`.
    /// - Parameters:
    ///   - defaults: The store holding the values.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}
