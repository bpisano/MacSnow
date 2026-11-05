//
//  MenuBarMenu.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import SwiftUI

/// Items of the menu bar menu: snow toggle, clear, quit.
struct MenuBarMenu<ViewModel: MenuBarViewModel>: View {
    @Bindable private var viewModel: ViewModel

    /// Creates the menu items.
    /// - Parameters:
    ///   - viewModel: State and actions of the menu.
    init(_ viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Toggle("Let it snow", isOn: $viewModel.isSnowing)
            .accessibilityIdentifier(MenuBarAccessibilityIdentifier.letItSnow)
        Button("Clear snow", action: viewModel.clearSnow)
            .disabled(!viewModel.canClearSnow)
            .accessibilityIdentifier(MenuBarAccessibilityIdentifier.clearSnow)
        Divider()
        Button("Quit MacSnow", action: viewModel.quit)
            .keyboardShortcut("q")
            .accessibilityIdentifier(MenuBarAccessibilityIdentifier.quit)
    }
}

#Preview("Not snowing") {
    MenuBarMenu(MockMenuBarViewModel())
}

#Preview("Snowing") {
    MenuBarMenu(MockMenuBarViewModel(isSnowing: true))
}
