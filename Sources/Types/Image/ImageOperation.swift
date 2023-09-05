import Foundation
import CoreImage

/// Image rotation fill options
public enum RotationFill {
    /// Crop and zoom to fill rectangular shape while preserving aspect ratio
    case crop

    /// Blur extended area, only odd numbers allowed for `kernel`
    /// Warning: not allowed for images with alpha channel
    case blur(kernel: UInt32)

    /// Fill extended area with color, use transparent (0, 0, 0, 0) for clear background
    /// Warning: Black color may appear instead of transparent for some formats (for example non-HEIF images without alpha channel)
    case color(alpha: UInt8, red: UInt8, green: UInt8, blue: UInt8)
}

/// Image operations
public enum ImageOperation: Equatable, Hashable, Comparable {
    /// Rotation
    /// Angle precision may wary between devices and methods (`vImage`, `CIImage`)
    /// The resulting images may have different dimension depending on destination format and device
    case rotate(_: Rotate, fill: RotationFill = .crop)

    /// Reflect vertically
    case flip

    /// Reflect horizontally (right to left mirror effect)
    case mirror

    /// Custom image processing function, appplied after all the other image operations
    /// Index used as a frame number, `0` for static images
    // case imageProcessing((_ image: CGImage, _ index: Int) -> CGImage) // vImage, CIImage

    /// Operation priority
    private var priority: Int {
        switch self {
        case .rotate(_, _):
            return 1
        case .flip:
            return 2
        case .mirror:
            return 3
        /*case .imageProcessing(_):
            // Should be executed after all the operations
            return 100*/
        }
    }

    /// Determine if `ImageOperation` is rotation and the angle isn't multiply of 90 degree
    public var isRotationByCustomAngle: Bool {
        if case .rotate(let rotation, _) = self {
            // Small threshold is used for small difference between types
            return abs(rotation.radians).truncatingRemainder(dividingBy: .pi/2) > 1e-6
        }
        return false
    }

    /// Hashable conformance
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .rotate(let value, _):
            hasher.combine(value)
        case .flip:
            hasher.combine("flip")
        case .mirror:
            hasher.combine("mirror")
        /*case .imageProcessing(_):
             hasher.combine("ImageProcessing")*/
        }
    }

    /// Equatable conformance
    public static func == (lhs: ImageOperation, rhs: ImageOperation) -> Bool {
        switch (lhs, rhs) {
        case (.rotate(let lhsRotation, _), .rotate(let rhsRotation, _)):
            return lhsRotation == rhsRotation
        case (.flip, .flip):
            return true
        case (.mirror, .mirror):
            return true
        default:
            return false
        }
    }

    /// Comparable conformance
    public static func < (lhs: ImageOperation, rhs: ImageOperation) -> Bool {
        return lhs.priority < rhs.priority
    }
}

public extension Set where Element == ImageOperation {
    /// Determine if any `ImageOperation` is rotation and the angle isn't multiply of 90 degree
    var containsRotationByCustomAngle: Bool {
        return self.contains(where: { $0.isRotationByCustomAngle })
    }
}
