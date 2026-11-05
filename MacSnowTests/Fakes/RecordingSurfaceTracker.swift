//
//  RecordingSurfaceTracker.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

@testable import MacSnow

final class RecordingSurfaceTracker: SurfaceTracking {
    private(set) var starts: Int = 0
    private(set) var stops: Int = 0

    func start() {
        starts += 1
    }

    func stop() {
        stops += 1
    }
}
