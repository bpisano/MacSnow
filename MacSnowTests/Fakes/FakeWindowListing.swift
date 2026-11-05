//
//  FakeWindowListing.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

@testable import MacSnow

final class FakeWindowListing: WindowListing {
    var records: [WindowRecord]

    init(records: [WindowRecord] = []) {
        self.records = records
    }

    func windows() -> [WindowRecord] {
        records
    }
}
