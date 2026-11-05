//
//  FakeDockReader.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics
@testable import MacSnow

final class FakeDockReader: DockReader {
    var frame: CGRect?

    init(frame: CGRect? = nil) {
        self.frame = frame
    }

    func tileRowFrame() -> CGRect? {
        frame
    }
}
