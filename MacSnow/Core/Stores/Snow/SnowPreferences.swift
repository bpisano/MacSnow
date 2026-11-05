//
//  SnowPreferences.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// Remembers whether snow is falling across launches.
protocol SnowPreferences: AnyObject {
    /// Whether snow was falling when last set.
    var isSnowing: Bool { get set }
}
