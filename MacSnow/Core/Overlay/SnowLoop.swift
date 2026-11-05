//
//  SnowLoop.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Metal
import QuartzCore

/// Advances a snow field over the current ledges and renders it into a Metal layer at every display refresh, 60 times per second.
@MainActor
final class SnowLoop: NSObject, @preconcurrency CAMetalDisplayLinkDelegate {
    private static let framesPerSecond: Float = 60
    private static let frameLatency: Float = 2

    private let displayLink: CAMetalDisplayLink
    private let renderer: any SnowRendering
    private let scale: Float
    private let surfaces: @MainActor () -> [SnowSurface]
    private let pointer: @MainActor () -> SIMD2<Float>
    private var field: SnowField
    private var flakes: (any MTLBuffer)?
    private var firstFrame: CFTimeInterval?
    private var fallingOut: AsyncStream<Void>.Continuation?

    /// Creates a stopped loop.
    /// - Parameters:
    ///   - layer: The layer whose drawables are rendered.
    ///   - renderer: Draws each frame.
    ///   - field: The flakes to advance and draw.
    ///   - surfaces: The ledges catching snow, front to back, in the field's points. Read every frame.
    ///   - pointer: Where the pointer is, in the field's points. Read every frame.
    init(
        layer: CAMetalLayer,
        renderer: any SnowRendering,
        field: SnowField,
        surfaces: @escaping @MainActor () -> [SnowSurface],
        pointer: @escaping @MainActor () -> SIMD2<Float>
    ) {
        displayLink = .init(metalLayer: layer)
        self.renderer = renderer
        scale = Float(layer.contentsScale)
        self.surfaces = surfaces
        self.pointer = pointer
        self.field = field
        flakes = renderer.upload(field.flakes)
        super.init()
        displayLink.preferredFrameRateRange = .init(
            minimum: Self.framesPerSecond,
            maximum: Self.framesPerSecond,
            preferred: Self.framesPerSecond
        )
        displayLink.preferredFrameLatency = Self.frameLatency
        displayLink.delegate = self
    }

    /// Starts rendering frames.
    func start() {
        displayLink.add(to: .main, forMode: .common)
    }

    /// Stops rendering frames for good.
    func stop() {
        displayLink.invalidate()
        fallingOut?.finish()
        fallingOut = nil
    }

    /// Spawns flakes again after `stopSpawning()`.
    func startSpawning() {
        fallingOut?.finish()
        fallingOut = nil
        field.startSpawning()
        flakes = renderer.upload(field.flakes)
    }

    /// Stops spawning flakes, lets the others fall out and the drifts melt.
    /// - Returns: Yields once the field is empty, finishes early when spawning starts again.
    func stopSpawning() -> AsyncStream<Void> {
        field.stopSpawning()
        flakes = renderer.upload(field.flakes)
        let (fellOut, continuation): (AsyncStream<Void>, AsyncStream<Void>.Continuation) = AsyncStream.makeStream()
        fallingOut?.finish()
        fallingOut = continuation
        return fellOut
    }

    /// Lets every drift fall off the screen, while snow keeps falling.
    func clearSnow() {
        field.clear()
    }

    /// Lays the field on the current ledges, advances it to the frame the display link asks for,
    /// lets the pointer sweep it, and renders it.
    /// - Parameters:
    ///   - link: The display link asking, on the main run loop.
    ///   - update: The frame to render.
    func metalDisplayLink(_ link: CAMetalDisplayLink, needsUpdate update: CAMetalDisplayLink.Update) {
        let start: CFTimeInterval = firstFrame ?? update.targetPresentationTimestamp
        firstFrame = start
        field.surfaces = surfaces()
        if field.advance(to: Float(update.targetPresentationTimestamp - start - field.epoch)) {
            flakes = renderer.upload(field.flakes)
        }
        field.movePointer(to: pointer())
        if field.isEmpty, let fallingOut {
            fallingOut.yield()
            fallingOut.finish()
            self.fallingOut = nil
        }
        let sprites: [SnowSprite] = field.grains.map(SnowSprite.init(grain:)) + field.puffs.map(SnowSprite.init(puff:))
        renderer.render(
            flakes,
            sprites: sprites,
            drifts: field.driftsBackToFront,
            with: .init(field: field, scale: scale),
            into: update.drawable
        )
    }
}
