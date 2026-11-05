//
//  MenuBarCoordinator.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import SwiftUI

/// Menu bar menu: composes `MenuBarMenu` with its view model.
struct MenuBarCoordinator: View {
    @State private var viewModel: UIMenuBarViewModel

    /// Creates the menu bar menu for `store`.
    /// - Parameters:
    ///   - store: The snow state the menu reads and drives.
    init(_ store: SnowStore) {
        viewModel = .init(store: store)
    }

    var body: some View {
        MenuBarMenu(viewModel)
    }
}

#Preview {
    MenuBarCoordinator(.init(preferences: InMemorySnowPreferences()))
}
