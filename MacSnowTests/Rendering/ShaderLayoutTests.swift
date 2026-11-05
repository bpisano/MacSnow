//
//  ShaderLayoutTests.swift
//  MacSnowTests
//
//  Created by Benjamin Pisano on 05/11/2026.
//

@testable import MacSnow
import Testing

@Suite
struct ShaderLayoutTests {
    @Test
    func `flakes are laid out as the shader reads them`() {
        #expect(MemoryLayout<SnowFlake>.stride == 13 * MemoryLayout<Float>.stride)
        #expect(MemoryLayout<SnowFlake>.offset(of: \.blur) == 12 * MemoryLayout<Float>.stride)
    }

    @Test
    func `uniforms are laid out as the shader reads them`() {
        #expect(MemoryLayout<SnowUniforms>.stride == 6 * MemoryLayout<Float>.stride)
        #expect(MemoryLayout<SnowUniforms>.offset(of: \.scale) == 5 * MemoryLayout<Float>.stride)
    }

    @Test
    func `drift uniforms are laid out as the shader reads them`() {
        #expect(MemoryLayout<SnowDriftUniforms>.stride == 8 * MemoryLayout<Float>.stride)
        #expect(MemoryLayout<SnowDriftUniforms>.offset(of: \.columns) == 5 * MemoryLayout<Float>.stride)
        #expect(MemoryLayout<SnowDriftUniforms>.offset(of: \.occluders) == 6 * MemoryLayout<Float>.stride)
        #expect(MemoryLayout<SnowDriftUniforms>.offset(of: \.offset) == 7 * MemoryLayout<Float>.stride)
    }

    @Test
    func `sprites are laid out as the shader reads them`() {
        #expect(MemoryLayout<SnowSprite>.stride == 6 * MemoryLayout<Float>.stride)
        #expect(MemoryLayout<SnowSprite>.offset(of: \.size) == 2 * MemoryLayout<Float>.stride)
        #expect(MemoryLayout<SnowSprite>.offset(of: \.turn) == 5 * MemoryLayout<Float>.stride)
    }
}
