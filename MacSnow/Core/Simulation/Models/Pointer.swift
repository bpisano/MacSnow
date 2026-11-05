//
//  Pointer.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

/// The pointer followed from frame to frame, in points with the origin at the bottom left of the screen.
struct Pointer: Sendable {
    /// Where the pointer was last seen, `nil` before the first frame.
    private(set) var position: SIMD2<Float>?
    /// When the pointer was last seen, in seconds.
    private(set) var time: Float = 0

    /// Follows the pointer to `position` at `time`.
    /// - Parameters:
    ///   - position: Where the pointer is now.
    ///   - time: The moment, in seconds.
    /// - Returns: The sweep since the last frame, `nil` on the first frame or when the pointer moved slowly.
    mutating func move(to position: SIMD2<Float>, at time: Float) -> Sweep? {
        let start: SIMD2<Float>? = self.position
        let duration: Float = time - self.time
        self.position = position
        self.time = time
        return start.flatMap { Sweep(from: $0, to: position, over: duration) }
    }

    /// Moves the moment the pointer was last seen back by `duration`, as the clock moves back.
    /// - Parameters:
    ///   - duration: How far the clock moves back, in seconds.
    mutating func rewind(by duration: Float) {
        time -= duration
    }
}
