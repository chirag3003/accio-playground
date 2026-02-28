import CoreML
import Vision
import UIKit

/// Performs YOLO object detection on camera frames
final class ObjectDetector {

    // MARK: - Properties

    private var visionModel: VNCoreMLModel?
    private var request: VNCoreMLRequest?

    private let detectionQueue = DispatchQueue(label: "com.accio.detection", qos: .userInitiated)

    /// Minimum confidence score (0-1) to include a detection
    var confidenceThreshold: Float = 0.35

    /// Callback invoked on the main thread with filtered detection results
    var onDetections: (([DetectionBox]) -> Void)?

    /// Propagated model load error, if any
    private(set) var modelLoadError: Error?

    // MARK: - Initialization

    init() {
        setupModel()
    }

    // MARK: - Public Methods

    /// Run detection on a pixel buffer
    func detect(pixelBuffer: CVPixelBuffer) {
        guard let request else { return }

        detectionQueue.async { [weak self] in
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Detection error: \(error)")
            }
        }
    }

    // MARK: - Private Methods

    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all

            // In .swiftpm playground apps, Xcode copies resources into the main bundle
            guard let modelURL = Bundle.main.url(forResource: "detectionModel", withExtension: "mlmodelc") else {
                struct ModelNotFoundError: Error, LocalizedError {
                    var errorDescription: String? { "YOLO model file not found in app bundle." }
                }
                modelLoadError = ModelNotFoundError()
                return
            }

            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            visionModel = try VNCoreMLModel(for: mlModel)

            request = VNCoreMLRequest(model: visionModel!) { [weak self] req, error in
                self?.processResults(request: req, error: error)
            }
            request?.imageCropAndScaleOption = .scaleFill

        } catch {
            modelLoadError = error
            print("Failed to load model: \(error)")
        }
    }

    private func processResults(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            DispatchQueue.main.async { [weak self] in self?.onDetections?([]) }
            return
        }

        let threshold = confidenceThreshold
        let detections: [DetectionBox] = results.compactMap { observation -> DetectionBox? in
            guard let label = observation.labels.first,
                  label.confidence >= threshold else { return nil }

            // Convert Vision coordinates (bottom-left origin) to SwiftUI (top-left origin)
            let bb = observation.boundingBox
            let rect = CGRect(
                x: bb.minX,
                y: 1 - bb.maxY,
                width: bb.width,
                height: bb.height
            )
            return DetectionBox(rect: rect, label: label.identifier, confidence: label.confidence)
        }

        DispatchQueue.main.async { [weak self] in
            self?.onDetections?(detections)
        }
    }
}
