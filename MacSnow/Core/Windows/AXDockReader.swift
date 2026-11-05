//
//  AXDockReader.swift
//  MacSnow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

import AppKit
import ApplicationServices

/// `DockReader` backed by Accessibility: the Dock's tile row is the list among its children.
/// Reads nothing until Accessibility is granted, and never asks for it.
struct AXDockReader: DockReader {
    private static let bundleIdentifier: String = "com.apple.dock"

    /// Reads the frame of the Dock's tile list.
    /// - Returns: The list frame in Core Graphics global coordinates, `nil` without Accessibility, Dock or list.
    func tileRowFrame() -> CGRect? {
        guard
            AXIsProcessTrusted(),
            let dock = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier).first
        else {
            return nil
        }
        let application: AXUIElement = AXUIElementCreateApplication(dock.processIdentifier)
        let children: [AXUIElement] = attribute(kAXChildrenAttribute, of: application) as? [AXUIElement] ?? []
        guard
            let list = children.first(where: { attribute(kAXRoleAttribute, of: $0) as? String == kAXListRole }),
            let origin: CGPoint = value(kAXPositionAttribute, of: list, as: .cgPoint),
            let size: CGSize = value(kAXSizeAttribute, of: list, as: .cgSize)
        else {
            return nil
        }
        return .init(origin: origin, size: size)
    }

    private func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private func value<Value>(_ name: String, of element: AXUIElement, as type: AXValueType) -> Value? {
        precondition(MemoryLayout<Value>.size == type.size, "\(Value.self) doesn't hold an AXValue of \(type)")
        guard let value = axValue(name, of: element) else {
            return nil
        }
        return withUnsafeTemporaryAllocation(of: Value.self, capacity: 1) { buffer in
            guard
                let address = buffer.baseAddress,
                AXValueGetValue(value, type, address)
            else {
                return nil
            }
            return address.move()
        }
    }

    private func axValue(_ name: String, of element: AXUIElement) -> AXValue? {
        guard
            let attribute = attribute(name, of: element),
            CFGetTypeID(attribute) == AXValueGetTypeID()
        else {
            return nil
        }
        return unsafeDowncast(attribute, to: AXValue.self)
    }
}

private extension AXValueType {
    /// Bytes of the value an `AXValue` of this type holds, `0` for types the Dock reader never asks for.
    var size: Int {
        switch self {
        case .cgPoint: MemoryLayout<CGPoint>.size
        case .cgSize: MemoryLayout<CGSize>.size
        case .cgRect: MemoryLayout<CGRect>.size
        case .cfRange: MemoryLayout<CFRange>.size
        default: 0
        }
    }
}
