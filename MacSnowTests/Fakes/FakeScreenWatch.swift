//
//  FakeScreenWatch.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

@testable import MacSnow

final class FakeScreenWatch: ScreenWatching {
    private let stream: AsyncStream<[SnowScreen]>
    private let continuation: AsyncStream<[SnowScreen]>.Continuation

    init(_ screens: [SnowScreen]) {
        (stream, continuation) = AsyncStream.makeStream()
        continuation.yield(screens)
    }

    func screens() -> AsyncStream<[SnowScreen]> {
        stream
    }

    func change(to screens: [SnowScreen]) {
        continuation.yield(screens)
    }
}
