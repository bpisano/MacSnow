//
//  SnowStoreTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

@testable import MacSnow
import Testing

@MainActor
@Suite
struct SnowStoreTests {
    @Test
    func `starts from the saved state`() {
        let store: SnowStore = .init(preferences: InMemorySnowPreferences(isSnowing: true))

        #expect(store.isSnowing)
    }

    @Test
    func `starting snow saves it`() {
        let preferences: InMemorySnowPreferences = .init()
        let store: SnowStore = .init(preferences: preferences)

        store.isSnowing.toggle()

        #expect(store.isSnowing)
        #expect(preferences.isSnowing)
    }

    @Test
    func `stopping snow saves it`() {
        let preferences: InMemorySnowPreferences = .init(isSnowing: true)
        let store: SnowStore = .init(preferences: preferences)

        store.isSnowing.toggle()

        #expect(!store.isSnowing)
        #expect(!preferences.isSnowing)
    }

    @Test
    func `saved state survives a relaunch`() {
        let preferences: InMemorySnowPreferences = .init()
        SnowStore(preferences: preferences).isSnowing = true

        let relaunched: SnowStore = .init(preferences: preferences)

        #expect(relaunched.isSnowing)
    }

    @Test
    func `clearing yields one request per call`() async {
        let store: SnowStore = .init(preferences: InMemorySnowPreferences(isSnowing: true))
        var requests: AsyncStream<Void>.Iterator = store.clearRequests.makeAsyncIterator()

        store.clear()
        store.clear()

        #expect(await requests.next() != nil)
        #expect(await requests.next() != nil)
    }
}
