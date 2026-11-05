//
//  UIMenuBarViewModelTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

@testable import MacSnow
import Testing

@MainActor
@Suite
struct UIMenuBarViewModelTests {
    @Test
    func `snow can be cleared while it falls`() {
        let viewModel: UIMenuBarViewModel = .init(store: .init(preferences: InMemorySnowPreferences(isSnowing: true)))

        #expect(viewModel.canClearSnow)
    }

    @Test
    func `snow cannot be cleared once it stopped`() {
        let viewModel: UIMenuBarViewModel = .init(store: .init(preferences: InMemorySnowPreferences(isSnowing: true)))

        viewModel.isSnowing = false

        #expect(!viewModel.canClearSnow)
    }

    @Test
    func `clearing snow asks the store`() async {
        let store: SnowStore = .init(preferences: InMemorySnowPreferences(isSnowing: true))
        let viewModel: UIMenuBarViewModel = .init(store: store)
        var requests: AsyncStream<Void>.Iterator = store.clearRequests.makeAsyncIterator()

        viewModel.clearSnow()

        #expect(await requests.next() != nil)
    }
}
