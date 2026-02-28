import Foundation

/// Represents a single object detection result from the ML model
struct DetectionBox: Identifiable {
    let id = UUID()
    let rect: CGRect     // Normalized coordinates (0-1, top-left origin)
    let label: String
    let confidence: Float
}
