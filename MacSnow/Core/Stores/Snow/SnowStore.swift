//
//  SnowStore.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Observation

/// Whether snow falls, persisted through `SnowPreferences`, and the requests to clear the snow lying on screen.
@MainActor
@Observable
final class SnowStore {
    /// Whether snow is falling. Every change is saved to the preferences.
    var isSnowing: Bool {
        didSet { preferences.isSnowing = isSnowing }
    }

    /// Yields once per `clear()`. Meant for a single consumer.
    @ObservationIgnored let clearRequests: AsyncStream<Void>

    @ObservationIgnored private let preferences: any SnowPreferences
    @ObservationIgnored private let clearing: AsyncStream<Void>.Continuation

    /// Creates a store starting from the saved state.
    /// - Parameters:
    ///   - preferences: Where the state is read from and saved to.
    init(preferences: any SnowPreferences) {
        self.preferences = preferences
        isSnowing = preferences.isSnowing
        (clearRequests, clearing) = AsyncStream.makeStream()
    }

    /// Asks to clear the snow lying on screen, through `clearRequests`.
    func clear() {
        clearing.yield()
    }
}
