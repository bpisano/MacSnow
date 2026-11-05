//
//  WindowListing.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// A source of the windows currently on screen.
protocol WindowListing {
    /// Lists the on-screen windows.
    /// - Returns: The windows, front to back.
    func windows() -> [WindowRecord]
}
