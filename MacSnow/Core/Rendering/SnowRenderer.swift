//
//  SnowRenderer.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import Metal
import OSLog
import QuartzCore

/// `SnowRendering` on the system GPU, with `Snow.metal`: one shaded quad per drift, then one point sprite per grain or puff,
/// then one per flake.
final class SnowRenderer: SnowRendering {
    private static let logger: Logger = .init(subsystem: "com.bpisano.MacSnow", category: "renderer")

    /// The system GPU.
    let device: any MTLDevice

    private let commandQueue: any MTLCommandQueue
    private let flakePipeline: any MTLRenderPipelineState
    private let spritePipeline: any MTLRenderPipelineState
    private let driftPipeline: any MTLRenderPipelineState

    /// Creates a renderer on the system GPU, `nil` when Metal or the snow shaders are unavailable.
    init?() {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue(),
            let library = device.makeDefaultLibrary(),
            let flakePipeline = Self.makePipeline(
                on: device,
                vertex: library.makeFunction(name: "snowFlakeVertex"),
                fragment: library.makeFunction(name: "snowFlakeFragment")
            ),
            let spritePipeline = Self.makePipeline(
                on: device,
                vertex: library.makeFunction(name: "snowSpriteVertex"),
                fragment: library.makeFunction(name: "snowFlakeFragment")
            ),
            let driftPipeline = Self.makePipeline(
                on: device,
                vertex: library.makeFunction(name: "snowDriftVertex"),
                fragment: library.makeFunction(name: "snowDriftFragment")
            )
        else {
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue
        self.flakePipeline = flakePipeline
        self.spritePipeline = spritePipeline
        self.driftPipeline = driftPipeline
    }

    private static func makePipeline(
        on device: any MTLDevice,
        vertex: (any MTLFunction)?,
        fragment: (any MTLFunction)?
    ) -> (any MTLRenderPipelineState)? {
        let descriptor: MTLRenderPipelineDescriptor = .init()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        let target: MTLRenderPipelineColorAttachmentDescriptor = descriptor.colorAttachments[0]
        target.pixelFormat = .bgra8Unorm
        target.isBlendingEnabled = true
        target.sourceRGBBlendFactor = .one
        target.sourceAlphaBlendFactor = .one
        target.destinationRGBBlendFactor = .oneMinusSourceAlpha
        target.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            Self.logger.error("Snow pipeline failed: \(error)")
            return nil
        }
    }

    /// Copies `flakes` to shared GPU memory.
    /// - Parameters:
    ///   - flakes: The flakes to draw from now on.
    /// - Returns: The GPU copy, `nil` when there is no flake to draw.
    func upload(_ flakes: [SnowFlake]) -> (any MTLBuffer)? {
        buffer(of: flakes)
    }

    /// Clears `drawable` to transparent, draws `drifts`, then `sprites`, then `flakes` over it, and presents it.
    /// - Parameters:
    ///   - flakes: The flakes, as returned by `upload(_:)`.
    ///   - sprites: The grains and puffs.
    ///   - drifts: The drifts, back to front.
    ///   - uniforms: The state of this frame.
    ///   - drawable: The drawable to fill and present.
    func render(
        _ flakes: (any MTLBuffer)?,
        sprites: [SnowSprite],
        drifts: [SnowDrift],
        with uniforms: SnowUniforms,
        into drawable: any CAMetalDrawable
    ) {
        let pass: MTLRenderPassDescriptor = .init()
        let target: MTLRenderPassColorAttachmentDescriptor = pass.colorAttachments[0]
        target.texture = drawable.texture
        target.loadAction = .clear
        target.clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        target.storeAction = .store
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)
        else {
            return
        }
        var frame: SnowUniforms = uniforms
        encoder.setVertexBytes(&frame, length: MemoryLayout<SnowUniforms>.stride, index: 1)
        encoder.setFragmentBytes(&frame, length: MemoryLayout<SnowUniforms>.stride, index: 1)
        encode(drifts, into: encoder)
        if let sprites = buffer(of: sprites) {
            encoder.setRenderPipelineState(spritePipeline)
            encoder.setVertexBuffer(sprites, offset: 0, index: 0)
            encoder.drawPrimitives(
                type: .point,
                vertexStart: 0,
                vertexCount: sprites.length / MemoryLayout<SnowSprite>.stride
            )
        }
        if let flakes {
            encoder.setRenderPipelineState(flakePipeline)
            encoder.setVertexBuffer(flakes, offset: 0, index: 0)
            encoder.drawPrimitives(
                type: .point,
                vertexStart: 0,
                vertexCount: flakes.length / MemoryLayout<SnowFlake>.stride
            )
        }
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func encode(_ drifts: [SnowDrift], into encoder: any MTLRenderCommandEncoder) {
        let piled: [(drift: SnowDrift, shape: SnowDriftUniforms)] = drifts
            .map { ($0, .init(drift: $0)) }
            .filter { $0.shape.peak > 0 }
        guard let heights = buffer(of: piled.flatMap(\.drift.heights)) else {
            return
        }
        encoder.setRenderPipelineState(driftPipeline)
        encoder.setFragmentBuffer(heights, offset: 0, index: 0)
        var offset: Int = 0
        for (drift, captured) in piled {
            var shape: SnowDriftUniforms = captured
            encoder.setVertexBytes(&shape, length: MemoryLayout<SnowDriftUniforms>.stride, index: 2)
            encoder.setFragmentBytes(&shape, length: MemoryLayout<SnowDriftUniforms>.stride, index: 2)
            var corners: [SIMD4<Float>] = occluderCorners(of: drift)
            encoder.setFragmentBytes(&corners, length: corners.count * MemoryLayout<SIMD4<Float>>.stride, index: 3)
            encoder.setFragmentBufferOffset(offset, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            offset += drift.heights.count * MemoryLayout<Float>.stride
        }
    }

    private func occluderCorners(of drift: SnowDrift) -> [SIMD4<Float>] {
        let corners: [SIMD4<Float>] = drift.occluders.map { rect in
            .init(Float(rect.minX), Float(rect.minY), Float(rect.maxX), Float(rect.maxY))
        }
        return corners + Array(repeating: .zero, count: SnowDrift.mostOccluders - corners.count)
    }

    private func buffer<Element>(of elements: [Element]) -> (any MTLBuffer)? {
        elements.withUnsafeBytes { bytes in
            guard !bytes.isEmpty, let base = bytes.baseAddress else { return nil }
            return device.makeBuffer(bytes: base, length: bytes.count, options: .storageModeShared)
        }
    }
}
