//
//  MenuBarIcon.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import SwiftUI

/// Snowflake shown in the menu bar, struck through while snow is not falling.
struct MenuBarIcon: View {
    private let isSnowing: Bool

    /// Creates the icon for the given snow state.
    /// - Parameters:
    ///   - isSnowing: Whether snow is falling.
    init(isSnowing: Bool) {
        self.isSnowing = isSnowing
    }

    /// The SF Symbol showing the snow state.
    var symbol: String {
        isSnowing ? "snowflake" : "snowflake.slash"
    }

    var body: some View {
        Image(systemName: symbol)
            .accessibilityLabel("MacSnow")
    }
}

#Preview("Not snowing") {
    MenuBarIcon(isSnowing: false)
}

#Preview("Snowing") {
    MenuBarIcon(isSnowing: true)
}
