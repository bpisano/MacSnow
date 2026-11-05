//
//  MenuBarIconTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

@testable import MacSnow
import Testing

@MainActor
@Suite
struct MenuBarIconTests {
    @Test
    func `shows a snowflake while snow falls`() {
        #expect(MenuBarIcon(isSnowing: true).symbol == "snowflake")
    }

    @Test
    func `shows a struck-through snowflake while snow does not fall`() {
        #expect(MenuBarIcon(isSnowing: false).symbol == "snowflake.slash")
    }
}
