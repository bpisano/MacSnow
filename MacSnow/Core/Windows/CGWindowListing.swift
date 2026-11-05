//
//  CGWindowListing.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import CoreGraphics

/// `WindowListing` backed by the window server. Reads bounds only: no permission needed.
struct CGWindowListing: WindowListing {
    /// Lists the on-screen windows, desktop elements excluded.
    /// - Returns: The windows, front to back.
    func windows() -> [WindowRecord] {
        let info: [[String: Any]] = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] ?? []
        return info.compactMap(WindowRecord.init(info:))
    }
}
